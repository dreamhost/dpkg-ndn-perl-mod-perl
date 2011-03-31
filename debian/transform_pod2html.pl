#!/usr/bin/perl
use strict;
use Carp;
use File::Find;
use File::Spec;
use Pod::Html;
use File::Path qw(make_path);
use File::Copy;

# dependencies
use Readonly;
use autodie qw(open close);
use HTML::Template;

Readonly my $CUR_DIR => $ARGV[0];
Readonly my $SRC_DIR => $ARGV[1];
Readonly my $DEST_DIR => $ARGV[2];
Readonly my $HTML_ROOT =>
    '/cgi-bin/dwww/usr/share/doc/libapache2-mod-perl2-doc';
croak "No source directory: $SRC_DIR" if not -d $SRC_DIR;
croak "No destination directory: $DEST_DIR" if not -d $DEST_DIR;

# This data structure will end up being
# a hierarchical index of the HTML formats of 
# the pod in the form expected by HTML::Template.
my %data = (pod=>[],sections=>[]);

find( \&transform_pod2html, $SRC_DIR );
my $template = HTML::Template->new(filename=>"$CUR_DIR/debian/index.tmpl", die_on_bad_params=>0);
$template->param(%data);
open my $fh,'>', "$CUR_DIR/$DEST_DIR/index.html";
print {$fh} $template->output;
close$fh;

exit(0);

sub transform_pod2html {
    return if $File::Find::dir =~ m{/\.svn};
    my $name = $_;
    return if $name eq '.svn';
    return if $name !~ m{\.(\w{3})$};
    my $ext = $1;
    return if $ext ne 'pod' and $ext ne 'png';
    my ($v, $directories, $file) = File::Spec->splitpath($File::Find::name);
    my @dirs = File::Spec->splitdir($directories);
    my $newdir = File::Spec->catdir($CUR_DIR, $DEST_DIR, @dirs);
    make_path($newdir, {verbose=>1});
    my $oldfile = File::Spec->catfile($CUR_DIR, $File::Find::name);
    if ($ext eq 'pod') {
        $name =~ s{\.pod$}{\.html};
    }
    my $newfile = File::Spec->catfile($newdir, $name);
    print "$File::Find::name -> $newfile\n";
    if ($ext eq 'pod') {
        pod2html(
            "--infile=$oldfile",
            "--outfile=$newfile",
            "--podroot=$CUR_DIR",
            "--verbose",
            "--htmldir=$CUR_DIR/debian/docs",
            "--htmlroot=$HTML_ROOT",
        );
    }
    else {
        copy($oldfile, $newfile);
    }
    my $new_url_dir = File::Spec->catdir($HTML_ROOT, '2.0', @dirs);    
    index_file($name, "/$new_url_dir/$name", $ext, @dirs);
    return;
}

sub index_file {
    my $name = shift;
    my $newfile = shift;
    my $ext = shift;
    my @dirs = @_;
    my $ptr = \%data;
    foreach my $d (@dirs) {
        last if $d eq '';
        $ptr = find_section($ptr, $d);
    }
    push @{$ptr->{$ext}}, {href=>$newfile,text=>$name};
    return;
}

sub find_section {
    my $ptr = shift;
    my $dir = shift;
    my @sections = @{$ptr->{sections}};
    foreach my $s (@sections) {
        return $s if $s->{title} eq $dir;
    }
    my %ldata = (title=>$dir,pod=>[],sections=>[],png=>[]);
    push @{$ptr->{sections}}, \%ldata;
    return \%ldata;
}
