use strict;
use warnings;
package Device::SMBus;

# PODNAME: Device::SMBus 
# ABSTRACT: Perl interface for smbus using libi2c-dev library.  
# COPYRIGHT
# VERSION

# Dependencies
use 5.010000;

use Moose;
use Carp;

use IO::File;
use Fcntl;

require XSLoader;
XSLoader::load('Device::SMBus', $VERSION);

=constant I2C_SLAVE

=cut

use constant I2C_SLAVE => 0x0703;

=attr I2CBusDevicePath

Device path of the I2C Device. 

 * On Raspberry Pi Model A this would usually be /dev/i2c-0 if you are using the default pins.
 * On Raspberry Pi Model B this would usually be /dev/i2c-1 if you are using the default pins.

=cut

has I2CBusDevicePath   => (
    is => 'ro',
);

has I2CBusFileHandle => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_I2CBusFileHandle',
);

=attr I2CDeviceAddress

This is the Address of the device on the I2C bus, this is usually available in the device Datasheet.

 * for /dev/i2c-0 look at output of `sudo i2cdetect -y 0' 
 * for /dev/i2c-1 look at output of `sudo i2cdetect -y 1' 

=cut

has I2CDeviceAddress => (
    is => 'ro',
);

has I2CBusFilenumber => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_I2CBusFilenumber',
);

sub _build_I2CBusFileHandle {
    my ($self) = @_;
    my $fh = IO::File->new( $self->I2CBusDevicePath, O_RDWR );
    if( !$fh ){
        croak "Unable to open I2C Device File at $self->I2CBusDevicePath";
        return -1;
    }
    $fh->ioctl(I2C_SLAVE,$self->I2CDeviceAddress);
    return $fh;
}

# Implicitly Call the lazy builder for the file handle by using it and get the filenumber
sub _build_I2CBusFilenumber {
    my ($self) = @_;
    $self->I2CBusFileHandle->fileno();
}

=method fileError

returns IO::Handle->error() for the device handle since the last clearerr

=cut

sub fileError {
    my ($self) = @_;
    return $self->I2CBusFileHandle->error();
}

=method writeQuick

$self->writeQuick($value)

=cut

sub writeQuick {
    my ($self,$value) = @_;
    my $retval = Device::SMBus::_writeQuick($self->I2CBusFilenumber,$value);
}

=method readByte

$self->readByte()

=cut

sub readByte {
    my ($self) = @_;
    my $retval = Device::SMBus::_readByte($self->I2CBusFilenumber);
}

=method writeByte

$self->writeByte()

=cut

sub writeByte {
    my ($self, $value) = @_;
    my $retval = Device::SMBus::_writeByte($self->I2CBusFilenumber,$value);
}

=method readByteData

$self->readByteData($register_address)

=cut

sub readByteData {
    my ($self,$register_address) = @_;
    my $retval = Device::SMBus::_readByteData($self->I2CBusFilenumber,$register_address);
}

=method writeByteData

$self->writeByteData($register_address,$value)

=cut

sub writeByteData {
    my ($self,$register_address,$value) = @_;
    my $retval = Device::SMBus::_writeByteData($self->I2CBusFilenumber,$register_address,$value);
}

=method readNBytes

$self->readNBytes($lowest_byte_address, $number_of_bytes);

Read together N bytes of Data in linear register order. i.e. to read from 0x28,0x29,0x2a 

$self->readNBytes(0x28,3);

=cut

sub readNBytes {
    my ($self,$reg,$numBytes) = @_;
    my $retval = 0;
    $retval = ($retval << 8) | $self->readByteData($reg+$numBytes - $_) for (1 .. $numBytes);
    return $retval;
}

=method readWordData

$self->readWordData($register_address)

=cut

sub readWordData {
    my ($self,$register_address) = @_;
    my $retval = Device::SMBus::_readWordData($self->I2CBusFilenumber,$register_address);
}

=method writeWordData

$self->writeWordData($register_address,$value)

=cut

sub writeWordData {
    my ($self,$register_address,$value) = @_;
    my $retval = Device::SMBus::_writeWordData($self->I2CBusFilenumber,$register_address,$value);
}

=method processCall

$self->processCall($register_address,$value)

=cut

sub processCall {
    my ($self,$register_address,$value) = @_;
    my $retval = Device::SMBus::_processCall($self->I2CBusFilenumber,$register_address,$value);
}

# Preloaded methods go here.
=method DEMOLISH

Destructor

=cut

sub DEMOLISH {
    my ($self) = @_;
    $self->I2CBusFileHandle->close();
}

1;

__END__

=begin wikidoc

= SYNOPSIS

  use Device::SMBus;
  $dev = Device::SMBus->new(
    I2CBusDevicePath => '/dev/i2c-1',
    I2CDeviceAddress => 0x1e,
  );
  print $dev->readByteData(0x20);

= DESCRIPTION

This is a perl interface to smbus interface using libi2c-dev library. 

Prerequisites:

* sudo apt-get install libi2c-dev i2c-tools

If you are using Angstrom Linux use the following:

* opkg install i2c-tools
* opkg install i2c-tools-dev

Enabling the I2C on a Raspberry Pi:

You will need to comment out the driver from the blacklist. currently the
I2C driver isn't being loaded.

    sudo vim /etc/modprobe.d/raspi-blacklist.conf

Replace this line 

    blacklist i2c-bcm2708

with this

    #blacklist i2c-bcm2708

You now need to edit the modules conf file.

    sudo vim /etc/modules

Add these two lines;

    i2c-dev
    i2c-bcm2708

Now run this command(replace 1 with 0 for older model Pi)

    sudo i2cdetect -y 1

you should now see the addresses of the i2c devices connected to your i2c bus


=end wikidoc

=begin html

<img alt=""
src="data:image/png;base64,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"
/>

=end html

=begin wikidoc

= USAGE

* This module provides a simplified object oriented interface to the libi2c-dev library for accessing electronic peripherals connected on the I2C bus. It uses Moose.

= see ALSO

* [Moose]
* [IO::File]
* [Fcntl]

=end wikidoc

=cut
