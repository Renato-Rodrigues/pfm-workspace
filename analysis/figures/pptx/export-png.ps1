# Export every slide of an editable figure deck to PNG at the printed size (Windows, PowerPoint).
#   pwsh analysis/figures/pptx/export-png.ps1 <deck.pptx> <out.png> [dpi]
# A one-slide figure deck gives one PNG; dpi defaults to the shared style (220).
param([Parameter(Mandatory)][string]$Deck, [Parameter(Mandatory)][string]$Out, [int]$Dpi = 220)
$Deck = (Resolve-Path $Deck).Path
$Out = [System.IO.Path]::GetFullPath($Out)
$pp = New-Object -ComObject PowerPoint.Application
try {
  $p = $pp.Presentations.Open($Deck, $true, $false, $false)
  $wpx = [int]($p.PageSetup.SlideWidth / 72 * $Dpi); $hpx = [int]($p.PageSetup.SlideHeight / 72 * $Dpi)
  $p.Slides(1).Export($Out, "PNG", $wpx, $hpx)
  $p.Close()
  "exported $Out ($wpx x $hpx px)"
} finally { $pp.Quit(); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($pp) | Out-Null }
