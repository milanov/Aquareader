package LoginWindow;

use strict;
use warnings;
use utf8;
use Gui::Windows::RegisterWindow;
use Aquareader::Feeds;
use Aquareader::News;
use Wx qw(:everything);
use Wx::Event qw(EVT_BUTTON);

use base qw(Wx::App);

sub OnInit {
	my $self = shift;

	# Initialize and center the main window
	my $frame = LoginWindowDialog->new(undef, -1, "Login to Aquareader");
	$frame->Centre();

	# Initialize and set the program icon
	Wx::InitAllImageHandlers();
	my $icon = Wx::Icon->new("Gui/resources/icon.png", wxBITMAP_TYPE_PNG, 16, 16);
	$frame->SetIcon($icon);

	# Show the window and wait for a user action
	$frame->Show(1);
	$frame->ShowModal();

	# Set our main window to be the top program window
	$self->SetTopWindow($frame);

	return 1;
}

package LoginWindowDialog;

use strict;
use warnings;
use utf8;
use Wx qw(:everything);
use Wx::Event qw(EVT_BUTTON);
use base qw(Wx::Dialog);

our ($username_input, $password_input);

sub new {
	my $class = shift;

	# Initialize the dialog window and center it
	my $self = $class->SUPER::new(@_);
	$self->CenterOnScreen();

	my ($ID_LOGIN, $ID_REGISTER, $ID_EXIT) = (1..3);

	# Create the main sizer
	my $topSizer = Wx::BoxSizer->new(wxVERTICAL);
	$self->SetSizer($topSizer);

	# Create a sizer for the inputs and the labels and add it to the main sizer
	my $boxSizer = Wx::BoxSizer->new(wxVERTICAL);
	$topSizer->Add($boxSizer, 0, wxALIGN_CENTER_HORIZONTAL | wxALL, 5);

	# Create a sizer for the username and add it to the box sizer
	my $username_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
	$boxSizer->Add($username_sizer, 0, wxGROW | wxALL, 5);

	# Create a label and an input for the username and add them to the inputs sizer
	my $username_label = Wx::StaticText->new($self, wxID_STATIC, "Username:");
	$username_sizer->Add($username_label, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

	# Create the input for the username and display it
	$username_input = Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition, [200, -1], 0);
	$username_sizer->Add($username_input, 0, wxGROW | wxALL, 5);

	# Create a sizer for the password and add it to the box sizer
	my $password_sizer = Wx::BoxSizer->new(wxHORIZONTAL);
	$boxSizer->Add($password_sizer, 0, wxGROW | wxALL, 5);

	# Create a label and an input for the username and add them to the inputs sizer
	my $password_label = Wx::StaticText->new($self, wxID_STATIC, "Password:");
	$password_sizer->Add($password_label, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

	# Create the input for the username and display it
	$password_input = Wx::TextCtrl->new($self, wxID_ANY, '', wxDefaultPosition, [200, -1], wxTE_PASSWORD);
	$password_sizer->Add($password_input, 0, wxGROW | wxALL, 5);

	# Draw a static horizonal line
	my $line = Wx::StaticLine->new($self, wxID_STATIC);
	$boxSizer->Add($line, 0, wxGROW | wxALL, 5);

	# Create a sizer for the login, register and exit buttons
	my $okCancelBox = Wx::BoxSizer->new(wxHORIZONTAL);
	$boxSizer->Add($okCancelBox, 0, wxALIGN_RIGHT | wxALL, 5);

	# Create and add an login, register and exit buttons to their sizer, placing them horizontally side by side
	my $login = Wx::Button->new($self, $ID_LOGIN, 'Login');
	$okCancelBox->Add($login, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);
	my $register = Wx::Button->new($self, $ID_REGISTER, 'Register');
	$okCancelBox->Add($register, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);
	my $exit = Wx::Button->new($self, $ID_EXIT, 'Exit');
	$okCancelBox->Add($exit, 0, wxALIGN_CENTER_VERTICAL | wxALL, 5);

	# Sizes the window so that it fits around its subwindows
	$topSizer->Fit($self);

	# Handle events for the login, register and exit buttons
	EVT_BUTTON($self, $ID_LOGIN, \&login);
	EVT_BUTTON($self, $ID_REGISTER, \&register);
	EVT_BUTTON($self, $ID_EXIT, \&close_window);

	return $self;
}

sub login {
	my ($self) = @_;

	# Get the username and password
	my $username = $username_input->GetValue();
	my $password = $password_input->GetValue();

	if(Login::login($username, $password)) {
		# Credentials are valid and the used is logged, so we close the login window
		$self->close_window();
	}
	else {
		Wx::MessageBox("Wrong username or password.");
	}
}

sub register {
	my ($self) = @_;

	# Close the login window
	$self->close_window();

	# Display the register window
	RegisterWindow->new();
}

sub close_window {
	my ($self) = @_;

	# Close the dialog window with a return code 0 and destroy the window
	$self->EndModal(0);
	$self->Destroy();
}

1;