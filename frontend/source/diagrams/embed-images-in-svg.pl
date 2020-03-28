#!/usr/bin/perl
##
# Embed image references into an SVG as data: urls.
#
# We could parse the whole file as XML, locate the nodes we were interested in,
# extract the data from the xlink namespaced attribute, read the file, replace
# the node content with the base64 encoded data URL and then serialise out the
# XML to a file. But seriously, who needs that kind of hassle.
#
# Syntax: embed-images-in-svg.pl <svg-file> <directory>
#

use MIME::Base64;

my $file = shift;
my $dir = shift;
my @content = ();

my %media_types = (
        'png' => 'image/png',
    );

sub create_data_uri {
    my ($link) = @_;
    my $data = '';
    my $media_type = 'application/octet-stream';

    open(my $fh, "$dir/$link") || die "Reading link '$link' failed: $!\n";
    sysread($fh, $data, -s "$dir/$link");
    close($fh);

    if ($link =~ /\.([^\.]+)$/ &&
        defined $media_types{$1})
    {
        $media_type = $media_types{$1};
    }

    $data = encode_base64($data);
    # encode_base64 appears to generate newlines in the content, which isn't
    # valid in a URI, so strip them out.
    $data =~ s/\n//g;

    return "data:$media_type;base64,$data";
}

open(my $fh, '<', $file) || die "Opening '$file' failed: $!\n";

while (<$fh>)
{
    s/(<image xlink:href=")([^"]+)/"$1" . create_data_uri($2)/eg;
    push @content, $_;
}
close($fh);

open($fh, '>', $file) || die "Creating '$file' failed: $!\n";
for my $line (@content) {
    print $fh $line;
}
close($fh);
