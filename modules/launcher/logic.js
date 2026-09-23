var fileResults = []

var fileIconMap = {
  pdf: { icon: "application-pdf", glyph: "" },
  doc: { icon: "x-office-document", glyph: "" },
  docx: { icon: "x-office-document", glyph: "" },
  odt: { icon: "x-office-document", glyph: "" },
  xls: { icon: "x-office-spreadsheet", glyph: "" },
  xlsx: { icon: "x-office-spreadsheet", glyph: "" },
  ods: { icon: "x-office-spreadsheet", glyph: "" },
  csv: { icon: "x-office-spreadsheet", glyph: "" },
  ppt: { icon: "x-office-presentation", glyph: "" },
  pptx: { icon: "x-office-presentation", glyph: "" },
  odp: { icon: "x-office-presentation", glyph: "" },
  txt: { icon: "text-x-generic", glyph: "" },
  md: { icon: "text-x-generic", glyph: "" },
  log: { icon: "text-x-generic", glyph: "" },
  png: { icon: "image-x-generic", glyph: "" },
  jpg: { icon: "image-x-generic", glyph: "" },
  jpeg: { icon: "image-x-generic", glyph: "" },
  gif: { icon: "image-x-generic", glyph: "" },
  webp: { icon: "image-x-generic", glyph: "" },
  svg: { icon: "image-x-generic", glyph: "" },
  bmp: { icon: "image-x-generic", glyph: "" },
  mp3: { icon: "audio-x-generic", glyph: "" },
  flac: { icon: "audio-x-generic", glyph: "" },
  wav: { icon: "audio-x-generic", glyph: "" },
  ogg: { icon: "audio-x-generic", glyph: "" },
  mp4: { icon: "video-x-generic", glyph: "" },
  mkv: { icon: "video-x-generic", glyph: "" },
  webm: { icon: "video-x-generic", glyph: "" },
  avi: { icon: "video-x-generic", glyph: "" },
  mov: { icon: "video-x-generic", glyph: "" },
  zip: { icon: "package-x-generic", glyph: "" },
  tar: { icon: "package-x-generic", glyph: "" },
  gz: { icon: "package-x-generic", glyph: "" },
  xz: { icon: "package-x-generic", glyph: "" },
  "7z": { icon: "package-x-generic", glyph: "" },
  rar: { icon: "package-x-generic", glyph: "" },
  js: { icon: "text-x-script", glyph: "" },
  ts: { icon: "text-x-script", glyph: "" },
  py: { icon: "text-x-script", glyph: "" },
  sh: { icon: "text-x-script", glyph: "" },
  qml: { icon: "text-x-script", glyph: "" },
  c: { icon: "text-x-csrc", glyph: "" },
  cpp: { icon: "text-x-c++src", glyph: "" },
  h: { icon: "text-x-chdr", glyph: "" },
  rs: { icon: "text-x-rust", glyph: "" },
  go: { icon: "text-x-go", glyph: "" },
  json: { icon: "application-json", glyph: "" },
  html: { icon: "text-html", glyph: "" },
  css: { icon: "text-css", glyph: "" }
}

function fileIconFor(name) {
  var dot = name.lastIndexOf(".")
  var ext = dot > 0 ? name.slice(dot + 1).toLowerCase() : ""
  var entry = fileIconMap[ext]
  if (entry)
    return entry
  return { icon: "text-x-generic", glyph: "" }
}

function filteredApps(apps, query) {
  var filtered = apps.filter(function (e) {
    return !e.noDisplay
  })
  if (query !== "") {
    filtered = filtered.filter(function (e) {
      return e.name.toLowerCase().includes(query) || (e.genericName && e.genericName.toLowerCase().includes(query))
    })
  }
  filtered.sort(function (a, b) {
    return a.name.localeCompare(b.name)
  })
  return filtered
}

function combinedResults(apps, files, query) {
  var appEntries = apps.map(function (e) {
    return { kind: "app", name: e.name, icon: e.icon, appData: e }
  })
  var results = query.length >= 2 ? appEntries.concat(files) : appEntries
  var mathResult = evaluateMath(query)
  if (mathResult !== null) {
    results = [{ kind: "calc", name: query.trim() + " = " + mathResult, result: String(mathResult) }].concat(results)
  }
  return results
}

function runFileSearch(query, fileSearchProcess) {
  if (query.length < 2) {
    return
  }
  var home = Quickshell.env("HOME") || ""
  var searchPaths = [
    home + "/Documents",
    home + "/Downloads",
    home + "/Dev",
    home + "/Videos",
    home + "/Images",
    home + "/screenshots",
    home + "/wallpapers"
  ]
  fileSearchProcess.exec({
    command: ["fd", "--type", "f", "--max-results", "30", "--", query].concat(searchPaths)
  })
}

function processFileSearchLine(line) {
  var path = line.trim()
  if (path === "")
    return null
  var parts = path.split("/")
  var name = parts[parts.length - 1]
  var dir = parts.slice(0, -1).join("/")
  var home = Quickshell.env("HOME")
  if (home && dir.indexOf(home) === 0)
    dir = "~" + dir.slice(home.length)
  var iconInfo = fileIconFor(name)
  return {
    kind: "file",
    name: name,
    path: path,
    dir: dir,
    icon: iconInfo.icon,
    glyph: iconInfo.glyph
  }
}

function launchSelected(combinedResults, selectedIndex) {
  if (combinedResults.length === 0)
    return
  var entry = combinedResults[selectedIndex]
  if (entry.kind === "app") {
    entry.appData.execute()
  } else if (entry.kind === "file") {
    Quickshell.execDetached(["xdg-open", entry.path])
  } else if (entry.kind === "calc") {
    Quickshell.execDetached(["wl-copy", entry.result])
  }
}

function evaluateMath(query) {
  var trimmed = query.trim()
  // only digits, operators, parens, decimal points, whitespace
  if (!/^[0-9+\-*/%^().\s]+$/.test(trimmed))
    return null
  // require at least one operator so plain numbers ("5", "42") don't trigger it
  if (!/[+\-*/%^]/.test(trimmed))
    return null
  var expr = trimmed.replace(/\^/g, "**")
  try {
    var result = Function('"use strict"; return (' + expr + ")")()
    if (typeof result !== "number" || !isFinite(result))
      return null
    return result
  } catch (e) {
    return null
  }
}

