#! /usr/bin/env perl

# This file is part of prosoda.  prosoda is free software: you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation, version 2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Copyright 2010, 2011 by Wolfgang Mauerer <wm@linux-kernel.net>
# Copyright 2012, 2013, Siemens AG, Wolfgang Mauerer <wolfgang.mauerer@siemens.com>
# All Rights Reserved.

use strict;

# Create \includegraphics  or \input (in minipages) commands for a number of images (in $files_ptr)
# using $cols (2nd argument) images per row.
sub gen_file_table($$$$;$) {
  my $files_ptr = shift;
  my $cols = shift;
  my $basename = shift;
  my $type = shift;
  my $labelfun = shift;

  my ($count, $res, $off, $file);
  my @files = @{$files_ptr};
  my $num = $#files + 1;

  $res = "";

  for ($count = 0; $count < int($num/$cols); $count++) {
    for ($off = 0; $off < $cols; $off++) {
      $file = $files[$count*$cols+$off];
      if ($type eq "input") {
	$res .= "\\begin{minipage}{" .  (1/$cols) . "\\linewidth}\n";
	if ($labelfun) {
	  $res .= &$labelfun($count*$cols+$off);
	}
	$res .= "\\input{$file}\n";
	$res .= "\\end{minipage}";
      } else {
	if ($labelfun) {
	  $res .= &$labelfun($count*$cols+$off);
	}
	$res .= "\\includegraphics[width=" . (1/$cols) . "\\linewidth]{$file}"
      }
    }
    if ($num > 0) {
	$res .= "\\\\\n";
    }
  }

  for ($count = 0; $count < $num % $cols; $count++) {
    $file = $files[$cols*int($num/$cols)+$count];
    if ($type eq "input") {
      $res .= "\\begin{minipage}{" .  (1/$cols) . "\\linewidth}\n";
      if ($labelfun) {
	$res .= &$labelfun($count*$cols+$off);
      }
      $res .= "\\input{$file}\n";
      $res .= "\\end{minipage}";
    } else {
      if ($labelfun) {
	$res .= &$labelfun($count*$cols+$off);
      }
      $res .= "\\includegraphics[width=" . (1/$cols) . "\\linewidth]{$file}"
    }
  }
  if ($num > 0) {
      $res .= "\\\\\n";
  }

  return $res;
}

sub gen_latex_iter($$$;$) {
  my $filespec = shift;
  my $cols = shift;
  my $type = shift;
  my $labelfun = shift;

  my $suffix = ".pdf";
  if ($type eq "input") {
    $suffix = ".tex";
  }

  my @files = split /\n/, `ls $filespec*$suffix 2>/dev/null`;
  return gen_file_table(\@files, $cols, $filespec, $type, $labelfun);
}

sub print_subsys_info($) {
    my $basedir = shift;
    print "\\newpage\\subsection{Subsystem Distribution in Clusters (Spin Glass)}\n";
    print "\\includegraphics[width=\\linewidth]{$basedir/sg_comm_subsys.pdf}";

    print "\\newpage\\subsection{Subsystem Distribution in Clusters (Random Walk, large)}\n";
    print "\\includegraphics[width=\\linewidth]{$basedir/wt_comm_subsys_big.pdf}";

    print "\\newpage\\subsection{Subsystem Distribution in Clusters (Random Walk, small)}\n";
    print "\\includegraphics[width=\\linewidth]{$basedir/wt_comm_subsys_small.pdf}";

    print "\\section{Statistical Summaries}\n";
    print "\\subsection{Statistical Summaries (Spin Glass Clusters)}\n";
    print "\\begin{small}\\renewcommand{\\tabcolsep}{2pt}\n";
    print gen_latex_iter("$basedir/sg_cluster_", 2, "input", sub($) { return("Cluster $_[0]\\\\\n")});
    print "\\end{small}\n";

    print "\\subsection{Statistical Summaries (Random Walk Clusters)}\n";
    print "\\begin{small}\\renewcommand{\\tabcolsep}{2pt}\n";
    print gen_latex_iter("$basedir/wt_cluster_", 2, "input", sub($) { return("Cluster $_[0]\\\\\n")});
    print "\\end{small}\n";
}

########################################################
if ($#ARGV != 1) {
  print "Usage: create_report.pl <datadir> {cycle}\n";
  exit(-1);
}

#my $basedir="/Users/wolfgang/papers/csd/cluster/res/32";
my $basedir=$ARGV[0];
my $cycle=$ARGV[1];

binmode(STDOUT, ":utf8");
print <<"END";
\\documentclass{article}
\\usepackage[landscape,a4paper,pdftex,top=5mm,bottom=5mm,left=5mm,right=5mm]{geometry}
\\usepackage{graphicx}
\\usepackage{calc}
\\usepackage{lmodern}
\\begin{document}
\\setlength{\\parindent}{0pt}
\\begin{center}
\\begin{Large}
\\textbf{Analysis Data for Development Cycle $cycle}
\\end{Large}
\\end{center}
\\section{Developer rankings}
\\begin{small}\\renewcommand{\\tabcolsep}{1pt}
\\begin{minipage}{0.5\\linewidth}
PageRank\\\\
\\input{$basedir/top20.pr.tex}
\\end{minipage}%
\\begin{minipage}{0.5\\linewidth}
PageRank (transposed)\\\\
\\input{$basedir/top20.pr.tr.tex}
\\end{minipage}

\\renewcommand{\\tabcolsep}{5pt}
\\begin{minipage}{0.5\\linewidth}
Number of commits\\\\
\\input{$basedir/top20.numcommits.tex}
\\end{minipage}%
\\begin{minipage}{0.5\\linewidth}
Changed lines\\\\
\\input{$basedir/top20.total.tex}
\\end{minipage}
\\end{small}
END

if (-e "$basedir/sg_comm_subsys.pdf") {
    print_subsys_info($basedir);
}

#################################
print "\\newpage\\section{Community Clusters (spin glass)}\n";
print "\\subsection{Cluster Contents (regular page rank)}\n";
print gen_latex_iter("$basedir/sg_reg_group_", 2, "includegraphics");

print "\\newpage\\subsection{Cluster Contents (transposed page rank)}\n";
print gen_latex_iter("$basedir/sg_tr_group_", 2, "includegraphics");

#########

print "\\newpage\\section{Community Clusters (random walk)}\n";
print "\\subsection{Cluster Contents (regular page rank)}\n";
print gen_latex_iter("$basedir/wt_reg_group_", 2, "includegraphics");

print "\\newpage\\subsection{Cluster Contents (transposed page rank)}\n";
print gen_latex_iter("$basedir/wt_tr_group_", 2, "includegraphics");

print "\\end{document}\n"
