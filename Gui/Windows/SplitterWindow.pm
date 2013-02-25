package SplitterWindow;

use strict;
use warnings;
use utf8;
use Wx qw(:everything);

use base qw(Wx::SplitterWindow);


sub new {
  my ($class, $parent_window) = @_;

  # Split the window into two subwindows
  my ($self) = $class->SUPER::new($parent_window, -1, wxDefaultPosition, wxDefaultSize, wxSP_LIVE_UPDATE|wxSP_BORDER);

  return $self;
}

1;