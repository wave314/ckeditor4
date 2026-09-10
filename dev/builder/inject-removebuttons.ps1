# Injects hardening options into the release config.js:
#   - config.removeButtons = 'Maximize,NewPage,Paste'  (hide UI buttons)
#   - config.versionCheck = false                       (disable version-check
#     requests to cke4.ckeditor.com, closing the domain-takeover XSS vector)
# Idempotent: skips options already present.

param(
	[string]$ConfigPath = 'release\ckeditor\config.js'
)

if (-not (Test-Path $ConfigPath)) {
	Write-Host "  [warn] $ConfigPath not found, skipping."
	exit 0
}

$content = [IO.File]::ReadAllText($ConfigPath)

# Config lines to inject (in order).
$injections = @(
	@{
		name = 'removeButtons'
		line = "`tconfig.removeButtons = 'Maximize,NewPage,Paste,PasteText,PasteFromWord';"
	},
	@{
		name = 'versionCheck'
		line = "`tconfig.versionCheck = false;"
	},
	@{
		name = 'fullPage'
		line = "`tconfig.fullPage = false;"
	}
)

# Idempotency: collect only the lines not yet present.
$missing = $injections | Where-Object { $content -notmatch $_.name }
if ($missing.Count -eq 0) {
	Write-Host "  [skip] all hardening options already present."
	exit 0
}

# Find the closing brace of editorConfig function and insert before it.
$marker = '};'
$idx = $content.LastIndexOf($marker)
$insertBlock = ($missing | ForEach-Object { $_.line }) -join "`n" + "`n"

if ($idx -lt 0) {
	Write-Host "  [warn] could not find closing brace, appending."
	$content += "`n" + $insertBlock
} else {
	$content = $content.Substring(0, $idx) + $insertBlock + $content.Substring($idx)
}

[IO.File]::WriteAllText($ConfigPath, $content)
$names = ($missing | ForEach-Object { $_.name }) -join ', '
Write-Host "  [ok] injected: $names"
