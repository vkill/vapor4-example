# App

## Run

```
sudo ln -sf $(pwd) /repos

head /repos/vapor4-example/Sources/App/app.swift

cp Config/main.toml.example Config/main.toml

/Library/Developer/Toolchains/swift-5.1-DEVELOPMENT-SNAPSHOT-2019-mm-dd-a.xctoolchain/usr/bin/swift package generate-xcodeproj

/Library/Developer/Toolchains/swift-5.1-DEVELOPMENT-SNAPSHOT-2019-mm-dd-a.xctoolchain/usr/bin/swift build

./.build/debug/Run
```
