# Example Stream Deck Plugin in Ruby

This is an example of a stream deck plugin written in Ruby.

The Stream Deck communicates with plugins via Web Sockets.  The `manifest.json` file tells the Stream Deck how to find the plugin executable and also specifies the icons.
The Stream Deck app will start the executable file, and pass connection information to the executable.
The executable must connect to the web socket, then let the Stream Deck know it has connected by sending a particular request.

## Installation

Just do this:

```
$ ln -s (realpath src/com.example.example-plugin.sdPlugin) ~/Library/Application\ Support/com.elgato.StreamDeck/Plugins/
```

Then restart the Stream Deck app.  The plugin should now be available!
