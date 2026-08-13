# BaGetter 🥖🛒

BaGetter is a lightweight [NuGet] and [symbol] server, written in C#.
It's forked from [BaGet] for progressive and community driven development.

![Build status] [![Docker image version]][Docker link] [![Discord][Discord image]][Discord link]

## 🚀 Getting Started

With Docker:

1. `docker run -p 5000:8080 -v ./bagetter-data:/data bagetter/bagetter:latest`
2. Use `http://localhost:5000/v3/index.json` as the NuGet package source

With .NET:

1. Install the [.NET SDK]
2. Download and extract [BaGetter's latest release]
3. Start the service with `dotnet BaGetter.dll`
4. Use `http://localhost:5000/v3/index.json` as the NuGet package source

This fork is API-only and does not include the Razor web interface.

To build BaGetter from source for Windows or Linux, including x64 and ARM64 self-contained builds, see the [PowerShell publishing guide](docs/PowerShell-Publishing.md).

With IIS ([official microsoft documentation](https://learn.microsoft.com/aspnet/core/host-and-deploy/iis)):

1. Install the [hosting bundle](https://dotnet.microsoft.com/permalink/dotnetcore-current-windows-runtime-bundle-installer)
2. Download the [zip release](https://github.com/bagetter/BaGetter/releases) of BaGetter
3. Unpack the zip file contents to a folder of your choice
4. Create a new or configure an existing IIS site to point its physical path to the folder where you unpacked the zip file

For more information, please refer to the [documentation].

## 📦 Features

* **Cross-platform**: runs on Windows, macOS, and Linux!
* **ARM** (64bit) **support**. You can host your NuGets on a device like Raspberry Pi!
* **Cloud native**: supports [Docker][Docker doc link], [AWS][AWS doc link], [Google Cloud][GCP doc link], [Alibaba Cloud][Aliyun doc link]，[Tencent Cloud][Tencent doc link]
* **Offline support**: [Mirror a NuGet server][Read through caching] to speed up builds and enable offline downloads

## 🤝 Contributing

We welcome contributions! Check out the [Contributing Guide](CONTRIBUTING.md) to get started.

## 📄 License

This project is licensed under the [MIT License](LICENSE).

## 📞 Contact

If you have questions, feel free to open an [issue] or join our [Discord Server][Discord link] for discussions.

## 🤝🏼 Contributors

Thanks to everyone who helps to make BaGetter better!

<a href="https://github.com/bagetter/BaGetter/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=bagetter/BaGetter" />
</a>


[Build status]: https://img.shields.io/github/actions/workflow/status/bagetter/BaGetter/.github/workflows/main.yml?logo=github&logoColor=fff

[Docker image version]: https://img.shields.io/docker/v/bagetter/bagetter?logo=docker&logoColor=fff&label=version
[Docker link]: https://hub.docker.com/r/bagetter/bagetter
[Docker doc link]: https://www.bagetter.com/docs/Installation/docker

[Discord image]: https://img.shields.io/discord/1181167608427450388?logo=discord&logoColor=fff
[Discord link]: https://discord.gg/XsAmm6f2hZ

[NuGet]: https://learn.microsoft.com/nuget/what-is-nuget
[symbol]: https://docs.microsoft.com/en-us/windows/desktop/debug/symbol-servers-and-symbol-stores
[.NET SDK]: https://www.microsoft.com/net/download
[Issue]: https://github.com/bagetter/BaGetter/issues
[BaGet]: https://github.com/loic-sharma/BaGet

[BaGetter's latest release]: https://github.com/bagetter/BaGetter/releases

[Documentation]: https://www.bagetter.com/
[Read through caching]: https://www.bagetter.com/docs/configuration#enable-read-through-caching
[AWS doc link]: https://www.bagetter.com/docs/Installation/aws
[GCP doc link]: https://www.bagetter.com/docs/Installation/gcp
[Aliyun doc link]: https://www.bagetter.com/docs/Installation/aliyun
[Tencent doc link]: https://www.bagetter.com/docs/Installation/tencent
