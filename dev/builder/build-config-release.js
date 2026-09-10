/**
 * @license Copyright (c) 2003-2023, CKSource Holding sp. z o.o. All rights reserved.
 * For licensing, see LICENSE.md or https://ckeditor.com/legal/ckeditor-oss-license
 */

// Release build config. Differs from build-config.js:
// 1. Adds 'release' to ignore so the output folder is not recursively copied into itself.
// 2. Excludes plugins from the build: about, elementspath, preview, print
//    (depends on preview, so both removed), save, pastefromword, pastetext,
//    iframe. codesnippetgeshi / iframedialog / pastefromgdocs are not in the
//    plugins list, so they are not built into the core either.
//    The corresponding plugin folders are removed post-build by build-release.bat
//    (the "post-build cleanup" step), because listing them in ignore caused
//    CKBuilder path resolution issues.
// 3. Excludes samples/ and other non-essential root files for a leaner release.
// 4. Buttons Maximize, NewPage, Paste are hidden via removeButtons injected
//    into the release config.js by build-release.bat (their plugins are kept
//    because clipboard/maximize/newpage are small and may be referenced).
/* exported CKBUILDER_CONFIG */

var CKBUILDER_CONFIG = {
	skin: 'moono-lisa',
	ignore: [
		'bender.js',
		'bender.ci.js',
		'.bender',
		'bender-err.log',
		'bender-out.log',
		'.travis.yml',
		'dev',
		'docs',
		'.DS_Store',
		'.editorconfig',
		'.gitignore',
		'.gitattributes',
		'.github',
		'gruntfile.js',
		'.idea',
		'.jscsrc',
		'.jshintignore',
		'.jshintrc',
		'less',
		'.mailmap',
		'.nvmrc',
		'node_modules',
		'package.json',
		'README.md',
		'release',
		'tests',
		// Non-essential sample/dev directories.
		'samples',
		// Non-essential root files in the build output.
		'bender-runner.config.json',
		'pnpm-lock.yaml',
		'SECURITY.md'
	],
	plugins: {
		a11yhelp: 1,
		basicstyles: 1,
		bidi: 1,
		blockquote: 1,
		clipboard: 1,
		colorbutton: 1,
		colordialog: 1,
		copyformatting: 1,
		contextmenu: 1,
		dialogadvtab: 1,
		div: 1,
		enterkey: 1,
		entities: 1,
		filebrowser: 1,
		find: 1,
		floatingspace: 1,
		font: 1,
		format: 1,
		forms: 1,
		horizontalrule: 1,
		htmlwriter: 1,
		image: 1,
		indentlist: 1,
		indentblock: 1,
		justify: 1,
		language: 1,
		link: 1,
		list: 1,
		liststyle: 1,
		magicline: 1,
		maximize: 1,
		newpage: 1,
		pagebreak: 1,
		pastefromlibreoffice: 1,
		editorplaceholder: 1,
		removeformat: 1,
		resize: 1,
		selectall: 1,
		showblocks: 1,
		showborders: 1,
		smiley: 1,
		sourcearea: 1,
		specialchar: 1,
		stylescombo: 1,
		tab: 1,
		table: 1,
		tableselection: 1,
		tabletools: 1,
		templates: 1,
		toolbar: 1,
		undo: 1,
		uploadimage: 1,
		wysiwygarea: 1
	}
};
