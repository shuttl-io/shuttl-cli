# shuttl-cli
The command line tool for building Shuttl files!

## Purpose
Shuttl enables you to build docker images with ease! The shuttl file is an abstraction on top of the docker file and allows you to use a single file to define multiple types of images

## Installation
To install Shuttl, simply run `sudo gem install shuttl --no-user-install`. Then run `shuttl install`

## Usage
Using Shuttl is easy! It supports all Docker file commands, with minor differences

For example, this Dockerfile: 
```dockerfile
FROM ubuntu
RUN apt install vim
```
becomes:
```ruby
FROM 'ubuntu'
RUN 'apt install vim'
```

### Extending other Shuttl files
Similar to Docker's `FROM`, Shuttl has an `EXTENDS` keyword. Unlike `FROM`, `EXTENDS` doesn't define multiple bild stages, meaning you don't have to worry about copying files around.

This may result in larger images, but it also allows for easier extending of files.

### Image Types
Shuttl also supports different image types. using the `ON` keyword, you can build different images for different build stages.

For example: 
```ruby
FROM 'ubuntu'

ON `dev` do 
  RUN 'echo "Doing this in develop!"'
end

ON 'production' do 
  RUN 'echo "Doing this in Production!"'
end
```
Shuttl will build two different images depending on what stage you build. `shuttl build --stage='dev'` would result in this dockerfile:
```dockerfile
FROM ubuntu
RUN echo "Doing this in develop!"
``` 

while `shuttl build --stage='PRODUCTION'` makes this dockerfile:
```dockerfile
FROM ubuntu
RUN echo "Doing this in Production!"
```

### `ONSTART`
This runs a command on container start. Prefer this over entrypoint. This is run before `ONRUN` commands

### `ONRUN`
Runs a command on container start. This is run after `ONSTART commands`

### `ATTACH`
Adds a local directory to the Image as a volume. The volume is automatically attached on start. 

Usage: `ATTACH <local path> <container_point>`

## Commands
### `shuttl build`
Builds the image using the Shuttlfile

####Args:
*--stage=STAGE:* The stage to build
*--file=FILE:* The file to build

### `shuttl start`
Starts the image

### `shuttl stop`
Stops the image

### `shuttl ssh`
Runs a bash instance inside the container.

### `shuttl run <COMMAND>`
Runs a command inside the container
