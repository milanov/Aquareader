use strict;
use warnings;
use utf8;
use Aquareader::CreateDB;
use Aquareader::Categories;
use Aquareader::Feeds;
use Aquareader::News;
use Aquareader::Settings;
use Aquareader::Login;
use Gui::AquareaderGui;
use Gui::Windows::LoginWindow;

my $db = $CreateDB::dbh;

CreateDB::create_tables_if_necessary();

if (!Login::get_current_user()) {
	LoginWindow->new();
}

while (Login::get_current_user()) {
	News::delete_old_news_if_necessary();

	my @feeds_ids = keys %{Feeds::get_feeds_names()};
	News::insert_news_if_necessary($_) foreach(@feeds_ids);

	my $app = AquareaderGui->new();
	$app->MainLoop();

	if (!Login::get_current_user()) {
		LoginWindow->new();
	} else {
		last;
	}
}