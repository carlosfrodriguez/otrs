# --
# Kernel/Modules/AdminSMIME.pm - to add/update/delete pgp keys
# Copyright (C) 2001-2004 Martin Edenhofer <martin+code@otrs.org>
# --
# $Id: AdminSMIME.pm,v 1.1 2004-08-04 13:12:48 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::Modules::AdminSMIME;

use strict;
use Kernel::System::Crypt;

use vars qw($VERSION);
$VERSION = '$Revision: 1.1 $';
$VERSION =~ s/^\$.*:\W(.*)\W.+?$/$1/;

# --
sub new {
    my $Type = shift;
    my %Param = @_;

    # allocate new hash for object
    my $Self = {};
    bless ($Self, $Type);

    # get common opjects
    foreach (keys %Param) {
        $Self->{$_} = $Param{$_};
    }

    # check all needed objects
    foreach (qw(ParamObject DBObject LayoutObject ConfigObject LogObject)) {
        die "Got no $_" if (!$Self->{$_});
    }

    $Self->{CryptObject} = Kernel::System::Crypt->new(%Param, CryptType => 'SMIME');

    return $Self;
}
# --
sub Run {
    my $Self = shift;
    my %Param = @_;
    my $Output = '';
    $Param{Search} = $Self->{ParamObject}->GetParam(Param => 'Search');
    if (!defined($Param{Search})) {
        $Param{Search} = $Self->{SMIMESearch} || '';
    }
    if ($Self->{Subaction} eq '' ) {
        $Param{Search} = '';
    }
    $Self->{SessionObject}->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key => 'SMIMESearch',
        Value => $Param{Search},
    );

    # delete key
    if ($Self->{Subaction} eq 'Delete') {
        my $Hash = $Self->{ParamObject}->GetParam(Param => 'Hash') || '';
        if (!$Hash) {
            my $Output .= $Self->{LayoutObject}->Header(Title => 'Error');
            $Output .= $Self->{LayoutObject}->Error(
                Message => 'Need param Hash to delete!',
            );
            $Output .= $Self->{LayoutObject}->Footer();
            return $Output;
        }
        my $Message = $Self->{CryptObject}->CertificateRemove(Hash => $Hash);

        my @List = $Self->{CryptObject}->CertificateSearch(Search => $Param{Search});
        foreach my $Key (@List) {
            $Self->{LayoutObject}->Block(
                Name => 'Row',
                Data => {
                    StartFont => '<font color ="red">',
                    StopFont => '</font>',
                    %{$Key},
                },
            );
        }
        my $Output = $Self->{LayoutObject}->Header(Area => 'Admin', Title => 'SMIME Management');
        $Output .= $Self->{LayoutObject}->AdminNavigationBar();
        if ($Message) {
            $Output .= $Self->{LayoutObject}->Notify(Info => $Message);
        }
        $Output .= $Self->{LayoutObject}->Output(TemplateFile => 'AdminSMIMEForm', Data => \%Param);
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }
    # add key
    elsif ($Self->{Subaction} eq 'Add') {
        $Self->{SessionObject}->UpdateSessionID(
            SessionID => $Self->{SessionID},
            Key => 'SMIMESearch',
            Value => '',
        );
        my %UploadStuff = $Self->{ParamObject}->GetUploadAll(
            Param => 'file_upload',
            Source => 'String',
        );
        if (!%UploadStuff) {
            my $Output .= $Self->{LayoutObject}->Header(Title => 'Error');
            $Output .= $Self->{LayoutObject}->Error(
                Message => 'Need Certificate!',
            );
            $Output .= $Self->{LayoutObject}->Footer();
            return $Output;
        }
        my $Message = $Self->{CryptObject}->CertificateAdd(Certificate => $UploadStuff{Content});
        if (!$Message) {
            $Message = $Self->{LogObject}->GetLogEntry(
                Type => 'Error',
                What => 'Message',
            );
        }
        my @List = $Self->{CryptObject}->CertificateSearch(Search => $Param{Search});
        foreach my $Key (@List) {
            $Self->{LayoutObject}->Block(
                Name => 'Row',
                Data => {
                    StartFont => '<font color ="red">',
                    StopFont => '</font>',
                    %{$Key},
                },
            );
        }
        my $Output = $Self->{LayoutObject}->Header(Area => 'Admin', Title => 'SMIME Management');
        $Output .= $Self->{LayoutObject}->AdminNavigationBar();
        $Output .= $Self->{LayoutObject}->Notify(Info => $Message);
        $Output .= $Self->{LayoutObject}->Output(TemplateFile => 'AdminSMIMEForm', Data => \%Param);
        $Output .= $Self->{LayoutObject}->Footer();
        return $Output;
    }
    # download key
    elsif ($Self->{Subaction} eq 'Download') {
        my $Hash = $Self->{ParamObject}->GetParam(Param => 'Hash') || '';
        if (!$Hash) {
            my $Output .= $Self->{LayoutObject}->Header(Title => 'Error');
            $Output .= $Self->{LayoutObject}->Error(
                Message => 'Need param Hash to download!',
            );
            $Output .= $Self->{LayoutObject}->Footer();
            return $Output;
        }
        my $Certificate = $Self->{CryptObject}->CertificateGet(Hash => $Hash);
        return $Self->{LayoutObject}->Attachment(
            ContentType => 'text/plain',
            Content => $Certificate,
            Filename => "$Hash.pem"
        );
    }
    # search key
    else {
        my @List = $Self->{CryptObject}->CertificateSearch(Search => $Param{Search});
        foreach my $Key (@List) {
            $Self->{LayoutObject}->Block(
                Name => 'Row',
                Data => {
                    StartFont => '<font color ="red">',
                    StopFont => '</font>',
                    %{$Key},
                },
            );
        }
        $Output .= $Self->{LayoutObject}->Header(Area => 'Admin', Title => 'SMIME Management');
        $Output .= $Self->{LayoutObject}->AdminNavigationBar();
        $Output .= $Self->{LayoutObject}->Output(TemplateFile => 'AdminSMIMEForm', Data => \%Param);
        $Output .= $Self->{LayoutObject}->Footer();
    }
    return $Output;
}
# --
1;
