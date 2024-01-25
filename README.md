# Spi

Crystal interface to the SPI driver on the Raspberry PI.
This uses the userland IOCTL SPI interface to send and receive data on the raspberry pi.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     spi:
       github: sleepinginsomniac/spi
   ```

2. Run `shards install`

## Usage

  ```crystal
  require "spi"

  device = Spi::Device.new("/dev/spidev0.0")
  device.mode = Spi::Mode::MODE_1
  device.bits_per_word = 8_u8
  device.baud = 800_000_u32 # 800KHz or whatever is supported

  # Send 1 byte
  data = Slice[0xAAu8] # etc.
  device.send(data)

  # Receive 10 bytes
  data = Slice(UInt8).new(10)
  device.receive(data)

  # Duplex data:
  dout = Slice[0xAAu8]
  din  = Slice(UInt8).new(1)
  device.transfer(send: dout, recv: din)
  ```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/sleepinginsomniac/spi/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Alex Clink](https://github.com/sleepinginsomniac) - creator and maintainer
