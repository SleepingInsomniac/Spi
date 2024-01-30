require "./ioctl"

module Spi
  VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}

  lib Lib
    struct IocTransfer
      tx_buf : Void*           # Pointer to userspace buffer with transmit data, or null (64 bits)
      rx_buf : Void*           # Pointer to userspace buffer for receive data, or null (64 bits)
      len : UInt32             # Length of tx and rx buffers, in bytes
      speed_hz : UInt32        # Temporary override of the device's bitrate
      delay_usecs : UInt16     # Delay after the last bit transfer before next transfer
      bits_per_word : UInt8    # Temporary override of the device's wordsize
      cs_change : UInt8        # True to deselect device before starting the next transfer
      tx_nbits : UInt8         # Number of bits for tx
      rx_nbits : UInt8         # Number of bits for rx
      word_delay_usecs : UInt8 # Delay between words within one transfer
      pad : UInt8              # Padding for alignment
    end
  end

  IOC_MAGIC = 'k'

  def self.message_size(n)
    size = n * sizeof(Lib::IocTransfer)
    max_size = (1 << IOCTL::SIZEBITS)
    size < max_size ? size : 0
  end

  def self.ioc_message(n)
    IOCTL._IOW(IOC_MAGIC, 0, sizeof(UInt8) * message_size(n))
  end

  IOC_RD_MODE = IOCTL._IOR(IOC_MAGIC, 1, sizeof(UInt8))
  IOC_WR_MODE = IOCTL._IOW(IOC_MAGIC, 1, sizeof(UInt8))

  IOC_RD_LSB_FIRST = IOCTL._IOR(IOC_MAGIC, 2, sizeof(UInt8))
  IOC_WR_LSB_FIRST = IOCTL._IOW(IOC_MAGIC, 2, sizeof(UInt8))

  IOC_RD_BITS_PER_WORD = IOCTL._IOR(IOC_MAGIC, 3, sizeof(UInt8))
  IOC_WR_BITS_PER_WORD = IOCTL._IOW(IOC_MAGIC, 3, sizeof(UInt8))

  IOC_RD_MAX_SPEED_HZ = IOCTL._IOR(IOC_MAGIC, 4, sizeof(UInt32))
  IOC_WR_MAX_SPEED_HZ = IOCTL._IOW(IOC_MAGIC, 4, sizeof(UInt32))

  IOC_RD_MODE32 = IOCTL._IOR(IOC_MAGIC, 5, sizeof(UInt32))
  IOC_WR_MODE32 = IOCTL._IOW(IOC_MAGIC, 5, sizeof(UInt32))

  @[Flags]
  enum Mode : UInt64
    CPHA           # clock phase
    CPOL           # clock polarity
    CSHigh         # chipselect active high?
    LSB_FIRST      # per-word bits-on-wire
    THREE_WIRE     # SI/SO signals shared
    LOOP           # loopback mode
    NO_CS          # 1 dev/bus, no chipselect
    READY          # slave pulls low to pause
    TX_DUAL        # transmit with 2 wires
    TX_QUAD        # transmit with 4 wires
    RX_DUAL        # receive with 2 wires
    RX_QUAD        # receive with 4 wires
    CS_WORD        # toggle cs after each word
    TX_OCTAL       # transmit with 8 wires
    RX_OCTAL       # receive with 8 wires
    THREE_WIRE_HIZ # high impedance turnaround
    RX_CPHA_FLIP   # CPHA on Rx only xfer

    MODE_0 = 0
    MODE_1 = CPHA
    MODE_2 = CPOL
    MODE_3 = CPOL | CPHA
  end

  MODE_USER_MASK = (1u64 << 17) - 1

  class Device
    @path : String
    @file : File

    def initialize(@path)
      @file = File.open(@path, "r+")
    end

    def finalize
      @file.close
    end

    def mode=(value)
      tmp = value.to_u8
      IOCTL.ioctl(@file.fd, IOC_WR_MODE, pointerof(tmp))
    end

    def mode
      value = 0u8
      IOCTL.ioctl(@file.fd, IOC_RD_MODE, pointerof(value))
      Mode.new(value.to_u64)
    end

    def mode32
      value = 0u32
      IOCTL.ioctl(@file.fd, IOC_RD_MODE32, pointerof(value))
      Mode.new(value.to_u64)
    end

    def bits_per_word=(value : UInt8)
      IOCTL.ioctl(@file.fd, IOC_WR_BITS_PER_WORD, pointerof(value))
    end

    def baud=(value : UInt32)
      IOCTL.ioctl(@file.fd, IOC_WR_MAX_SPEED_HZ, pointerof(value))
    end

    def send(buffer : Slice, delay_usecs : UInt16?)
      transfer(buffer, nil, delay_usecs)
    end

    def receive(buffer : Slice, delay_usecs : UInt16?)
      transfer(nil, buffer, delay_usecs)
    end

    def transfer(send : Slice? | Pointer, recv : Slice?, delay_usecs : UInt16?)
      tf = Spi::Lib::IocTransfer.new

      tf.tx_buf = send.to_unsafe.as(Void*) if send
      tf.rx_buf = recv.to_unsafe.as(Void*) if recv
      delay_usecs.try { |us| tf.delay_usecs = us }

      len = {send.try(&.bytesize) || 0, recv.try(&.bytesize) || 0}.max
      tf.len = len

      IOCTL.ioctl(@file.fd, Spi.ioc_message(1), pointerof(tf))

      tf
    end
  end
end
