# ShellS3

Need to quickly upload and get a link to a file? This small Bash script will help you do just that.

A small(ish) shells script to upload files top S3 from the command line.

The files are automatically given a timestamp suffix to avoid naming conflicts.

For example, `image.png` will be uploaded as `image-1430566517.png`.

## Usage

1. Put the [script](shells3.sh) somewhere in PATH (e.g. /usr/local/bin).

    ```sh
    cp shells3.sh /usr/local/bin/shells3
    ```

2. Add a configuration file to `~/.shells3.conf`. See [shells3.sample.conf](shells3.sample.conf) for a description of the configuration options.

    ```sh
    cp shells3.sample.conf ~/.shells3.conf
    vim ~/.shells3.conf # Edit the configuration in your favourite editor
    ```

3. Upload a file

    ```sh
    shells3 image.png
    ```

## Compatibility and dependencies

Only tested on OS X 10.10 Yosemite, but the script should work on any unix-like operating system. Aside from Bash, the only dependency is [curl](http://curl.haxx.se/).

## License and Copyright

The MIT License (MIT). Copyright (c) 2015 Matias Korhonen

Based on Chris Parsons's [s3.sh](http://git.io/vJ45L).
