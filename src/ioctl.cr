# Adapted from asm-generic/ioctl.h

module IOCTL
  extend self

  NRBITS   = 8
  TYPEBITS = 8

  SIZEBITS = 14
  DIRBITS  =  2

  NRMASK   = ((1 << NRBITS) - 1)
  TYPEMASK = ((1 << TYPEBITS) - 1)
  SIZEMASK = ((1 << SIZEBITS) - 1)
  DIRMASK  = ((1 << DIRBITS) - 1)

  NRSHIFT   = 0
  TYPESHIFT = (NRSHIFT + NRBITS)
  SIZESHIFT = (TYPESHIFT + TYPEBITS)
  DIRSHIFT  = (SIZESHIFT + SIZEBITS)

  enum Dir : UInt32
    None  = 0
    Write = 1
    Read  = 2
  end

  def _IOC(dir : Dir, type : Int | Char, nr : Int, size : Int) : UInt32
    (dir.value << DIRSHIFT) | \
      ((type.is_a?(Char) ? type.ord : type) << TYPESHIFT) | \
        (nr << NRSHIFT) | \
        (size << SIZESHIFT)
  end

  def _IO(*args)
    _IOC(Dir::None, *args, 0)
  end

  def _IOR(*args)
    _IOC(Dir::Read, *args)
  end

  def _IOW(*args)
    _IOC(Dir::Write, *args)
  end

  def _IOWR(*args)
    _IOC(Dir::Read | Dir::Write, *args)
  end

  def _DIR(nr)
    (nr >> DIRSHIFT) & DIRMASK
  end

  def _TYPE(nr)
    (nr >> TYPESHIFT) & TYPEMASK
  end

  def _NR(nr)
    (nr >> NRSHIFT) & NRMASK
  end

  def _SIZE(nr)
    (nr >> SIZESHIFT) & SIZEMASK
  end

  # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  lib C
    fun ioctl(fd : Int32, request : UInt32, ...) : Int32
  end

  def ioctl(fd, request, *args)
    result = C.ioctl(fd, request, *args)

    if result == -1
      STDERR.puts "Errno: #{Errno.value}"
      raise "#{Errno.value.message}"
    end
  end
end
