#!/usr/bin/perl

use strict;
use warnings;

my $gitoutput = `git log --reverse --format='Date: %aD%n%B'`;

# Read the list of version numbers that we're going to ignore and those we'll change.
my %ignore_versions;
my %replace_versions;
open(my $fh, '<', 'versions.munge');
while (<$fh>)
{
    chomp;
    if (/(\d+) s\/(.*)\/(.*)\//)
    {
        my $num = $1 + 0;
        my ($from, $to) = ($2, $3);
        if (!defined $replace_versions{$num})
        {
            $replace_versions{$num} = [];
        }
        push @{ $replace_versions{$num} }, [$from, $to];
    }
    elsif (/(\d+)/)
    {
        my $num = $1 + 0;
        $ignore_versions{$num} = 1;
    }
}

my $commitnumber = 0;
my $acc = '';
my $date = '';
my $subject = undef;

sub output
{
    my ($commitnumber, $date, $subject, $acc) = @_;
    if (!$subject)
    { return; }

    # Skip the version if it's not been excluded.
    if ($ignore_versions{$commitnumber})
    { return; }

    if (defined $replace_versions{$commitnumber})
    {
        for my $pair (@{ $replace_versions{$commitnumber} })
        {
            my ($from, $to) = @$pair;
            # print STDERR "$commitnumber : $from -> $to\n";
            $subject =~ s/$from/$to/gs;
            $acc =~ s/$from/$to/gs;
        }
    }

    $subject =~ s/&/&amp;/g;
    $subject =~ s/</&lt;/g;
    $subject =~ s/>/&gt;/g;

    $acc =~ s/&/&amp;/g;
    $acc =~ s/</&lt;/g;
    $acc =~ s/>/&gt;/g;
    $acc =~ s/\n+//s;

    $acc =~ s/\n\n/\n<\/p>\n\n<p>\n/g;
    $acc = "<p>$acc</p>";
    $acc =~ s/<p>\s*<\/p>\s*//g;
    print "<version number='$commitnumber' date='$date'><em>$subject</em>\n";
    print "$acc\n";
    print "</version>\n\n";
}

my @commits;
for my $line (split /\n/, $gitoutput)
{
    # Date in the form: Date: Sun, 8 Mar 2020 21:35:57 +0000
    if ($line =~ /^Date: ..., (\d+ ... \d\d\d\d)/)
    {
        my $newdate = $1;
        $commits[$commitnumber] = [$commitnumber, $date, $subject, $acc];
        $commitnumber += 1;
        $date = $newdate;
        $subject = '';
        $acc = '';
    }
    elsif (!$subject)
    {
        $subject = $line;
    }
    else
    {
        $acc .= "$line\n";
    }
}

$commits[$commitnumber] = [$commitnumber, $date, $subject, $acc];

for my $num (reverse(1..$commitnumber))
{
    my $commit = $commits[$num];
    my ($commitnumber, $date, $subject, $acc) = @$commit;
    print STDERR "Commit: $num\n";

    output($commitnumber, $date, $subject, $acc);
}
