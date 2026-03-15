param(
  [Parameter(Mandatory = $true)]
  [string]$Path,

  [string]$ReplaceExact,
  [string]$With,
  [string]$InsertAfter,
  [string]$Text,
  [string]$InsertBefore,
  [string]$TextBefore,
  [string]$EnsureContains
)

$fullPath = [System.IO.Path]::GetFullPath($Path)
$content = [System.IO.File]::ReadAllText($fullPath)
$newline = if ($content.Contains("`r`n")) { "`r`n" } elseif ($content.Contains("`n")) { "`n" } else { [Environment]::NewLine }
$modeCount = 0

if ($PSBoundParameters.ContainsKey('ReplaceExact')) { $modeCount++ }
if ($PSBoundParameters.ContainsKey('InsertAfter')) { $modeCount++ }
if ($PSBoundParameters.ContainsKey('InsertBefore')) { $modeCount++ }
if ($PSBoundParameters.ContainsKey('EnsureContains')) { $modeCount++ }

if ($modeCount -ne 1) {
  throw 'Choose exactly one edit mode: ReplaceExact, InsertAfter, InsertBefore, or EnsureContains.'
}

if ($PSBoundParameters.ContainsKey('ReplaceExact')) {
  if (-not $PSBoundParameters.ContainsKey('With')) {
    throw 'ReplaceExact requires -With.'
  }

  if (-not $content.Contains($ReplaceExact)) {
    throw 'ReplaceExact target not found.'
  }

  $updated = $content.Replace($ReplaceExact, $With)
}
elseif ($PSBoundParameters.ContainsKey('InsertAfter')) {
  if (-not $PSBoundParameters.ContainsKey('Text')) {
    throw 'InsertAfter requires -Text.'
  }

  $index = $content.IndexOf($InsertAfter)
  if ($index -lt 0) {
    throw 'InsertAfter marker not found.'
  }

  $insertAt = $index + $InsertAfter.Length
  $updated = $content.Insert($insertAt, $Text)
}
elseif ($PSBoundParameters.ContainsKey('InsertBefore')) {
  if (-not $PSBoundParameters.ContainsKey('TextBefore')) {
    throw 'InsertBefore requires -TextBefore.'
  }

  $index = $content.IndexOf($InsertBefore)
  if ($index -lt 0) {
    throw 'InsertBefore marker not found.'
  }

  $updated = $content.Insert($index, $TextBefore)
}
else {
  if ($content.Contains($EnsureContains)) {
    $updated = $content
  }
  else {
    $separator = if ($content.EndsWith($newline) -or [string]::IsNullOrEmpty($content)) { '' } else { $newline }
    $updated = $content + $separator + $EnsureContains
  }
}

$encoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($fullPath, $updated, $encoding)
