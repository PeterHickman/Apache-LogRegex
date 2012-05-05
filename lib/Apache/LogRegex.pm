package Apache::LogRegex;

use strict;
use warnings;

our $VERSION = '1.5';

sub new {
    my ( $class, $format ) = @_;

	die "Apache::LogRegex->new() takes 1 argument" if scalar(@_) != 2;
	die "Apache::LogRegex->new() argument 1 (FORMAT) is undefined" if !defined($format);

    my $self = bless {}, $class;

    $self->{_format} = $format;

    $self->{_regex_string} = '';
    $self->{_regex_fields} = ();

    $self->_parse_format();

    return $self;
}

sub _parse_format {
    my ($self) = @_;

    chomp( $self->{_format} );
    $self->{_format} =~ s#[ \t]+# #;
    $self->{_format} =~ s#^ ##;
    $self->{_format} =~ s# $##;

    my @regex_elements;

    foreach my $element ( split ( ' ', $self->{_format} ) ) {
        my $quotes = ( $element =~ m/^\\\"/ ) ? 1 : 0;

        if ($quotes) {
            $element =~ s/^\\\"//;
            $element =~ s/\\\"$//;
        }

        push ( @{ $self->{_regex_fields} }, $self->rename_this_name($element) );

        my $x = '(\S*)';

        if ($quotes) {
			if($element eq '%r' or $element =~ m/{Referer}/ or $element =~ m/{User-Agent}/) {
				$x = qr/"([^"\\]*(?:\\.[^"\\]*)*)"/;
			}
			else {
            	$x = '\"([^\"]*)\"';
			}
        }
        elsif ( $element =~ m/^%.*t$/ ) {
            $x = '(\[[^\]]+\])';
        }
		elsif ( $element eq '%U' ) {
			$x = '(.+?)';
		}

        push ( @regex_elements, $x );
    }

	my $regex = join ( ' ', @regex_elements );
	$self->{_regex_string} = qr/^$regex\s*$/;
}

sub parse {
    my ( $self, $line ) = @_;

	die "Apache::LogRegex->parse() takes 1 argument" if scalar(@_) != 2;
	die "Apache::LogRegex->parse() argument 1 (LINE) is undefined" if !defined($line);

    chomp($line);

    my @temp = $line =~ m/$self->{_regex_string}/;

    return if scalar(@temp) == 0;

    my %data;
    @data{ @{ $self->{_regex_fields} } } = @temp;

    return %data;
}

sub names {
    my ($self) = @_;

	die "Apache::LogRegex->names() takes no argument" if scalar(@_) != 1;

    return ( @{ $self->{_regex_fields} } );
}

sub regex {
    my ($self) = @_;

	die "Apache::LogRegex->regex() takes no argument" if scalar(@_) != 1;

    return $self->{_regex_string};
}

sub rename_this_name {
    my ( $self, $name ) = @_;

    return $name;
}

1;

=head1 NAME

Apache::LogRegex - Parse a line from an Apache logfile into a hash

=head1 VERSION

This document refers to version 1.5 of Apache::LogRegex, released November 20th 2008

=head1 SYNOPSIS

  use Apache::LogRegex;

  my $lr;

  eval { $lr = Apache::LogRegex->new($log_format) };
  die "Unable to parse log line: $@" if ($@);

  my %data;

  while ( my $line_from_logfile = <> ) {
      eval { %data = $lr->parse($line_from_logfile); };
      if (%data) {
          # We have data to process
      } else {
          # We could not parse this line
      }
  }

=head1 DESCRIPTION

=head2 Overview

Designed as a simple class to parse Apache log files. It will construct
a regex that will parse the given log file format and can then parse
lines from the log file line by line returning a hash of each line.

The field names of the hash are derived from the log file format. Thus if
the format is '%a %t \"%r\" %s %b %T \"%{Referer}i\" ...' then the keys of
the hash will be %a, %t, %r, %s, %b, %T and %{Referer}i.

Should these key names be unusable, as I guess they probably are, then subclass
and provide an override rename_this_name() method that can rename the keys 
before they are added in the array of field names.

=head2 Constructors and initialization

=over 4

=item Apache::LogRegex->new( FORMAT )

Returns a Apache::LogRegex object that can parse a line from an Apache
logfile that was written to with the FORMAT string. The FORMAT
string is the CustomLog string from the httpd.conf file.

=back

=head2 Class and object methods

=over 4

=item parse( LINE )

Given a LINE from an Apache logfile it will parse the line and
return a hash of all the elements of the line indexed by their
format. If the line cannot be parsed an empty hash will be
returned.

=item names()

Returns a list of field names that were extracted from the data. Such as
'%a', '%t' and '%r' from the above example.

=item regex()

Returns a copy of the regex that will be used to parse the log file.

=item rename_this_name( NAME )

Use this method to rename the keys that will be used in the returned hash.
The initial NAME is passed in and the method should return the new name.

=back

=head1 ENVIRONMENT

Perl 5

=head1 DIAGNOSTICS

The only problem I can foresee is the various custom time formats but
providing that they are encased in '[' and ']' all should be fine.

=over 4

=item Apache::LogRegex->new() takes 1 argument

When the constructor is called it requires one argument. This message is
given if more or less arguments were supplied.

=item Apache::LogRegex->new() argument 1 (FORMAT) is undefined

The correct number of arguments were supplied with the constructor call,
however the first argument, FORMAT, was undefined.

=item Apache::LogRegex->parse() takes 1 argument

When the method is called it requires one argument. This message is
given if more or less arguments were supplied.

=item Apache::LogRegex->parse() argument 1 (LINE) is undefined

The correct number of arguments were supplied with the method call,
however the first argument, LINE, was undefined.

=item Apache::LogRegex->names() takes no argument

When the method is called it requires no arguments. This message is
given if some arguments were supplied.

=item Apache::LogRegex->regex() takes no argument

When the method is called it requires no arguments. This message is
given if some arguments were supplied.

=back

=head1 BUGS

None so far

=head1 FILES

None

=head1 SEE ALSO

mod_log_config for a description of the Apache format commands

=head1 AUTHOR

Peter Hickman (peterhi@ntlworld.com)

=head1 COPYRIGHT

Copyright (c) 2004, Peter Hickman. All rights reserved. This module is
free software. It may be used, redistributed and/or modified under the
same terms as Perl itself.
