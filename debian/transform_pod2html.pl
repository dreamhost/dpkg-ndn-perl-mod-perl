#!/usr/bin/perl
use strict;
use Carp;
use File::Find;
use File::Spec;
use Pod::Html;
use File::Path qw(make_path);

# dependencies: libreadonly-perl
use Readonly;

Readonly my $CUR_DIR => $ARGV[0];
Readonly my $SRC_DIR => $ARGV[1];
Readonly my $DEST_DIR => $ARGV[2];
croak "No source directory: $SRC_DIR" if not -d $SRC_DIR;
croak "No destination directory: $DEST_DIR" if not -d $DEST_DIR;

find( \&transform_pod2html, $SRC_DIR );

sub transform_pod2html {
    return if $File::Find::dir =~ m{/\.svn};
    my $name = $_;
    return if $name eq '.svn';
    return if $name !~ m{\.pod$};
    my ($v, $directories, $file) = File::Spec->splitpath($File::Find::name);
    $name =~ s{\.pod$}{\.html};
    my @dirs = File::Spec->splitdir($directories);
    shift @dirs; # should be 'docs'
    my $newdir = File::Spec->catdir($CUR_DIR, $DEST_DIR, @dirs);
    make_path($newdir, {verbose=>1});
    my $newfile = File::Spec->catfile($newdir, $name);
    my $oldfile = File::Spec->catfile($CUR_DIR, $File::Find::name);
    print "$File::Find::name -> $newfile\n";
    pod2html("--infile=$oldfile", "--outfile=$newfile");
}
