/**
 * @license Copyright (c) 2003-2023, CKSource Holding sp. z o.o. All rights reserved.
 * For licensing, see LICENSE.md or https://ckeditor.com/legal/ckeditor-oss-license
 */

'use strict';

( function() {

	// Detects whether a CDATA value contains a raw HTML opening tag.
	// Legitimate CDATA content (CSS in <style>, JS in <script>) does not
	// contain "<" immediately followed by a letter; such a pattern indicates
	// injected markup attempting to bypass ACF.
	function containsHtmlTag( value ) {
		return /<[a-zA-Z]/.test( value );
	}

	/**
	 * A lightweight representation of HTML CDATA.
	 *
	 * @class
	 * @extends CKEDITOR.htmlParser.node
	 * @constructor Creates a cdata class instance.
	 * @param {String} value The CDATA section value.
	 */
	CKEDITOR.htmlParser.cdata = function( value ) {
		/**
		 * The CDATA value.
		 *
		 * @property {String}
		 */
		this.value = value;
	};

	CKEDITOR.htmlParser.cdata.prototype = CKEDITOR.tools.extend( new CKEDITOR.htmlParser.node(), {
		/**
		 * CDATA has the same type as {@link CKEDITOR.htmlParser.text} This is
		 * a constant value set to {@link CKEDITOR#NODE_TEXT}.
		 *
		 * @readonly
		 * @property {Number} [=CKEDITOR.NODE_TEXT]
		 */
		type: CKEDITOR.NODE_TEXT,

		filter: function( filter ) {
			var style = this.getAscendant( 'style' );

			if ( style ) {
				// MathML and SVG namespaces processing parsers `style` content as a normal HTML, not text.
				// Make sure to filter such content also.
				var nonHtmlElementNamespace = style.getAscendant( { math: 1, svg: 1 } );

				if ( nonHtmlElementNamespace ) {
					var fragment = CKEDITOR.htmlParser.fragment.fromHtml( this.value ),
						writer = new CKEDITOR.htmlParser.basicWriter();

					filter.applyTo( fragment );
					fragment.writeHtml( writer );

					this.value = writer.getHtml();
				}
			}

			// Security fix (CVE CDATA/ACF bypass): CDATA content (inside
			// <style>/<script>) is normally raw CSS/JS and must NOT contain
			// HTML tags. If it does, an attacker injected malicious markup
			// (e.g. <img onerror>) to bypass ACF. HTML-encode it so it can
			// never execute when written back to the DOM.
			if ( containsHtmlTag( this.value ) ) {
				this.value = CKEDITOR.tools.htmlEncode( this.value );
			}
		},

		/**
		 * Writes the CDATA, HTML-encoding it if it contains HTML tags
		 * (defense-in-depth against CDATA/ACF bypass XSS).
		 *
		 * @param {CKEDITOR.htmlParser.basicWriter} writer The writer to which write the HTML.
		 */
		writeHtml: function( writer ) {
			var value = this.value;

			// Defense-in-depth: even if filter() did not run (e.g. ACF skips
			// NODE_TEXT nodes), ensure CDATA carrying HTML tags is encoded
			// before being written to the DOM.
			if ( containsHtmlTag( value ) ) {
				value = CKEDITOR.tools.htmlEncode( value );
			}

			writer.write( value );
		}
	} );
} )();
