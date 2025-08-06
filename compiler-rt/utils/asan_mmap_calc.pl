#!/usr/bin/perl -w
use strict;
use diagnostics;

my $BYTES_PER_GIGABYTE = (1024 ** 3);
my $BYTES_PER_TERABYTE = (1024 ** 4);


my ($ratio, $vmaBits, $shadowBase);

# HWASan dynamic example, with 4GB HighMem
$ratio = 16;
$vmaBits = 48;
$shadowBase = 0xefff00000000;
# High mem:    [ffff00000000, ffffffffffff] 4.00GB
# High shadow: [fffef0000000, fffeffffffff] 0.25GB
# Shadow gap:  [fefef0000000, fffeefffffff] 1024.00GB
# Low shadow:  [efff00000000, fefeefffffff] 15359.75GB
# Low mem:     [0, effeffffffff] 245756.00GB

# ASan fixed shadow (x86-64 Linux), just below 2GB
$ratio = 8;
$vmaBits = 47;
$shadowBase = 0x00007fff8000;
# High mem:    [0x10007fff8000, 0x7fffffffffff] 114686.00GB
# High shadow: [0x2008fff7000, 0x10007fff7fff] 14335.75GB
# Shadow gap:  [0x8fff7000, 0x2008fff6fff] 2048.00GB
# Low shadow:  [0x7fff8000, 0x8fff6fff] 0.25GB
# Low mem:     [0x0, 0x7fff7fff] 2.00GB

# HWASan dynamic example, with 4TB LowMem
$ratio = 16;
$vmaBits = 48;
$shadowBase = 4 * (1024 ** 4);
# High mem:    [0x140000000000, 0xffffffffffff] 241664.00GB
# High shadow: [0x54000000000, 0x13ffffffffff] 15104.00GB
# Shadow gap:  [0x44000000000, 0x53fffffffff] 1024.00GB
# Low shadow:  [0x40000000000, 0x43fffffffff] 256.00GB
# Low mem:     [0x0, 0x3ffffffffff] 4096.00GB

# ASan fixed shadow (AArch64 48-bit Linux)
$ratio = 8;
$vmaBits = 48;
$shadowBase = 0x0000001000000000;
# High mem:    [0x201000000000, 0xffffffffffff] 229312.00GB
# High shadow: [0x41200000000, 0x200fffffffff] 28664.00GB
# Shadow gap:  [0x1200000000, 0x411ffffffff] 4096.00GB
# Low shadow:  [0x1000000000, 0x11ffffffff] 8.00GB
# Low mem:     [0x0, 0xfffffffff] 64.00GB

my $lowMemStart = 0;
my $lowMemEnd   = $shadowBase - 1;
my $lowMemSize  = $lowMemEnd - $lowMemStart + 1;

my $lowShadowStart = $shadowBase;
my $lowShadowEnd   = $shadowBase + (($lowMemEnd - $lowMemStart) / $ratio);
my $lowShadowSize  = $lowShadowEnd - $lowShadowStart + 1;

my $highMemEnd   = (2**$vmaBits) - 1;
# LowShadow + ShadowGap + HighShadow = (2**$vmaBits) / $ratio
my $highMemStart = $lowMemEnd + (2**$vmaBits) / $ratio + 1;
my $highMemSize  = $highMemEnd - $highMemStart + 1;

my $shadowGapStart = $lowShadowEnd + 1;
my $shadowGapEnd   = $shadowGapStart + (2**$vmaBits) / ($ratio * $ratio) - 1;
my $shadowGapSize  = $shadowGapEnd - $shadowGapStart + 1;

my $highShadowStart = $shadowGapEnd + 1;
my $highShadowEnd   = $highMemStart - 1;
my $highShadowSize  = $highShadowEnd - $highShadowStart + 1;


print "Parameters:\n";
print "- ratio:      $ratio\n";
print "- vmaBits:    $vmaBits\n";
print "- shadowBase: $shadowBase\n";
print "\n";
printf "High mem:    [0x%x, 0x%x] %.2lfGB\n", $highMemStart, $highMemEnd, $highMemSize / $BYTES_PER_GIGABYTE;
printf "High shadow: [0x%x, 0x%x] %.2lfGB\n", $highShadowStart, $highShadowEnd, $highShadowSize / $BYTES_PER_GIGABYTE;
printf "Shadow gap:  [0x%x, 0x%x] %.2lfGB\n", $shadowGapStart, $shadowGapEnd, $shadowGapSize / $BYTES_PER_GIGABYTE;
printf "Low shadow:  [0x%x, 0x%x] %.2lfGB\n", $lowShadowStart, $lowShadowEnd, $lowShadowSize / $BYTES_PER_GIGABYTE;
printf "Low mem:     [0x%x, 0x%x] %.2lfGB\n", $lowMemStart, $lowMemEnd, $lowMemSize / $BYTES_PER_GIGABYTE;

#die unless $highShadowSize == int ($highMemSize / $ratio);
