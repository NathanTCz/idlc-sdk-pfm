# @title Getting Started Guide

## `pfm` Executable
Bundled with this gem is an executable `pfm`. The `pfm` executable is a command-line tool that does the following:

  * Generates server build repositories, templates, and default cookbooks
  * Builds images with Packer from existing server build repositories
  * Validates server build repositories, templates, and cookbooks

The following commands are available in PFM 0.3.x (see pfm -h for a full list):

```
Usage:
    pfm -h/--help
    pfm -v/--version
    pfm command [arguments...] [options...]


Available Commands:
    generate   Generate a new server build, repository, cookbooks, etc.
    build      Build a specified server template
    validate   Test & validate a server build
    exec       Runs the command in context of the embedded ruby
    configure  Run initial setup and configuration
    plan       Show the infrastructure plan
    apply      Apply the infrastructure plan
    destroy    Destroy all managed infrastructure
    format     format infrastructure code
```

### Configuring `pfm`
#### `.pfm/` Options Directory
The `pfm` executable will automatically generate a default config file located at `.pfm/config`. It will set sensible defaults, that should work for most implementations. You can change these settings by editing the file directly or running `pfm configure`.

See available settings in {Pfm::Settings}

### `pfm` Commands
#### pfm generate server-build
Use the `pfm generate server-build` subcommand to generate server build repositories/templates.

##### Syntax
```
$ pfm generate server-build NAME [options]
```

##### Options
`-h`, `--help`
  - Show this message

`-V`, `--verbose`
  - Show detailed output from the generator

`-v`, `--version`
  - Show pfm version

##### Examples
To generate a server build repositories, run a command similar to:

```
$ pfm generate server-build app-axpwa
```


#### pfm build
Use the `pfm build` subcommand to build server images (using Packer) from existing build repositories & templates (previously generated from `pfm generate`)

##### Syntax
```
$ pfm build BUILD_NAME [options]
```

##### Options
This subcommand has the following options:

`-a VERSION`, `--app-release VERSION`
  - Application Version Number to build

`-n`, `--build-number NUMBER`
  - Override the build number. Default is ENV::BUILD_NUMBER

`-t`, `--build-template TEMPLATE`
  - The Packer Build Template to use. The default template file is `build.json`. This file should reside in the root of the server build directory.

`-m`, `--build-metadata METADATA_FILE`
  - The build metadata file to use. The default metadata file is `metadata`. This file should reside in the root of the server build directory.

`-h`, `--help`
  - Show this message

`-V`, `--verbose`
  - Show detailed output from the generator

`-v`, `--version`
  - Show pfm version

##### Examples
To build a server repositories/template, run a command similar to:

```
$ pfm build app-axpwa -a 3.1.0.1585
```

#### pfm validate server-build
Use the `pfm validate server-build` subcommand to validate a server build repository. This will run various tools such as Foodcritic, Rubocop, and ChefSpec against the build repo. Reports & Artifacts are generated and stored in `.pfm/tests/{reports,artifacts}`

##### Syntax
```
$ pfm validate server-build BUILD_NAME [options]
```

##### Options
`-t`, `--build-template TEMPLATE`
  - The Build Template to use. Default is `build.json`

`-m`, `--build-metadata METADATA_FILE`
  - The build metadata file to use. The default metadata file is `metadata`. This file should reside in the root of the server build directory.

`-c`, `--circle-ci`
  - Use Circle Ci artifact output directories

`-h`, `--help`
  - Show this message

`-V`, `--verbose`
  - Show detailed output from the generator

`-v`, `--version`
  - Show pfm version

##### Examples
To validate a build repository, run a command similar to:

```
$ pfm validate server-build app-axpwa
```
#### pfm validate infrastructure
Use the `pfm validate infrastructure` subcommand to validate a server build repository. This will run various tools such as Foodcritic, Rubocop, and ChefSpec against the build repo. Reports & Artifacts are generated and stored in `.pfm/tests/{reports,artifacts}`

##### Syntax
```
$ pfm validate infrastructure [options]
```

##### Options
`-h`, `--help`
  - Show this message

`-V`, `--verbose`
  - Show detailed output from the generator

`-v`, `--version`
  - Show pfm version

##### Examples
To validate a build repository, run a command similar to:

```
$ pfm validate infrastructure
```

#### pfm exec
Use the `pfm exec` subcommand to run arbitrary shell commands with the PATH environment variable and the GEM_HOME and GEM_PATH Ruby environment variables pointed at the Pfm bundle.

##### Syntax
```
$ pfm exec SYSTEM_COMMAND [options]
```

##### Options
`-h`, `--help`
  - Show this message

`-V`, `--verbose`
  - Show detailed output from the generator

`-v`, `--version`
  - Show pfm version

##### Examples
None.

#### pfm plan
Use the `pfm plan` subcommand to plan infrastructure changes before they are executed.

##### Syntax
```
$ pfm plan [options]
```

##### Options

`-a`, `--app-release VERSION`
  - Application Version Number to Deploy

`-b`, `--server-build BUILD_NUMBER`
  - The build number of the AMI to deploy

`-l`, `--landscape`
  - Format the Terraform plan output with `terraform_landscape`

`-h`, `--help`
  - Show this message

`-V`, `--verbose`
  - Show detailed output

`-v`, `--version`
  - Show pfm version

##### Examples
To plan an infrastructure release with application version number 3.1.0.1654, run a command similar to:

```
$ pfm plan -a 3.1.0.1654
```

#### pfm apply
Use the `pfm apply` subcommand to apply infrastructure changes before they are executed.

##### Syntax
```
$ pfm apply [options]
```

##### Options

`-a`, `--app-release VERSION`
  - Application Version Number to Deploy

`-b`, `--server-build BUILD_NUMBER`
  - The build number of the AMI to deploy

`-h`, `--help`
  - Show this message

`-V`, `--verbose`
  - Show detailed output

`-v`, `--version`
  - Show pfm version

##### Examples
To apply an infrastructure release with application version number 3.1.0.1654, run a command similar to:

```
$ pfm apply -a 3.1.0.1654
```

#### pfm destroy
Use the `pfm destroy` subcommand to destroy a managed environment and all associated resources. THIS CANNOT BE UNDONE

##### Syntax
```
$ pfm destroy [options]
```

##### Options

`-h`, `--help`
  - Show this message

`-V`, `--verbose`
  - Show detailed output

`-v`, `--version`
  - Show pfm version

##### Examples
To destroy a managed environment

```
$ pfm destroy
```

#### pfm format
Use the `pfm format` subcommand to format an infrastructure repository and associated files to a canonical format.

##### Syntax
```
$ pfm format [options]
```

##### Options

`-h`, `--help`
  - Show this message

`-V`, `--verbose`
  - Show detailed output

`-v`, `--version`
  - Show pfm version

##### Examples
To format an infrastructure repository's files

```
$ pfm format
```
