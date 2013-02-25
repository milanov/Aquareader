package AquareaderGui;

use strict;
use warnings;
use utf8;
use Gui::Windows::MainWindow;
use Aquareader::Login qw(get_names);
use Wx qw(:everything);

use base qw(Wx::App);

sub OnInit {
	my $self  = shift;

	# Initialize and center the main window
	my $frame = MainWindow->new(undef, -1, "Aquareader", wxDefaultPosition, [900, 600]);
	$frame->Centre();

	# Initialize and set the program icon
	Wx::InitAllImageHandlers();
	my $icon = Wx::Icon->new("Gui/resources/icon.png", wxBITMAP_TYPE_PNG, 16, 16);
	$frame->SetIcon($icon);
	$frame->Show(1);

	# Set our main window to be the top program window
	$self->SetTopWindow($frame);

	return 1;
}

1;