# SafariDownload
Swift package to read Safari's download packages

> Note: This package just reads a few of the available keys in the plist in the download bundle. It might be in-comprehensive or incorrect.

Get the current download progress:

```swift
let download = try SafariDownloadModel(
    url: URL(fileURLWithPath: "/Users/me/Downloads/MyFile.zip.download"),
    noObservation: true
)

print(download.originURL)
print(download.bytesDownloaded)
print(model.bytesTotal)
```

Observe the download progress with Combine:

```swift
let download = try SafariDownloadModel(
    url: URL(fileURLWithPath: "/Users/me/Downloads/MyFile.zip.download")
)

download.$bytesDownloaded.sink { byteCount in
  print("Currently downloaded: \(byteCount) bytes")
}.store(in: &subscriptions)
```

__Credits__: Marin Todorov, [https://underplot.com](underplot.com)

__License__: MIT
