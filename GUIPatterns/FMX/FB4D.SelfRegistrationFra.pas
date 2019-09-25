unit FB4D.SelfRegistrationFra;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Edit, FMX.Controls.Presentation,
  FB4D.Interfaces;

type
  TFraSelfRegistration = class(TFrame)
    AniIndicator: TAniIndicator;
    btnCheckEMail: TButton;
    btnResetPwd: TButton;
    btnSignIn: TButton;
    btnSignUp: TButton;
    edtEMail: TEdit;
    txtEMail: TText;
    edtPassword: TEdit;
    txtPassword: TText;
    lblStatus: TLabel;
    procedure edtEMailChangeTracking(Sender: TObject);
    procedure btnCheckEMailClick(Sender: TObject);
    procedure btnSignInClick(Sender: TObject);
    procedure btnSignUpClick(Sender: TObject);
    procedure btnResetPwdClick(Sender: TObject);
  private
    fConfig: IFirebaseConfiguration;
    fOnUserLogin: TOnUserResponse;
    procedure StartTokenReferesh(const LastToken: string);
    procedure OnFetchProviders(const EMail: string; IsRegistered: boolean;
      Providers: TStrings);
    procedure OnFetchProvidersError(const Info, ErrMsg: string);
    procedure OnResetPwd(const Info: string; Response: IFirebaseResponse);
    procedure OnUserError(const Info, ErrMsg: string);
    procedure OnUserResponse(const Info: string; User: IFirebaseUser);
    procedure OnTokenRefresh(TokenRefreshed: boolean);
    procedure OnGetUserData(FirebaseUserList: TFirebaseUserList);
  public
    procedure Initialize(Config: IFirebaseConfiguration;
      OnUserLogin: TOnUserResponse; const LastRefreshToken: string = '';
      const LastEMail: string = '');
    procedure StartEMailEntering;
  end;

implementation

uses
  FB4D.Helpers;

{$R *.fmx}

resourcestring
  rsEnterEMail = 'Enter your e-mail address for registration';
  rsWait = 'Please wait for Firebase';
  rsEnterPassword = 'Enter your password for registration';
  rsSetupPassword = 'Setup a new password for future registrations';
  rsPleaseCheckEMail = 'Please check your e-mail inbox to renew your password.';
  rsLoggedIn = 'Successful logged in';

procedure TFraSelfRegistration.Initialize(Config: IFirebaseConfiguration;
  OnUserLogin: TOnUserResponse; const LastRefreshToken, LastEMail: string);
begin
  fConfig := Config;
  fOnUserLogin := OnUserLogin;
  edtEMail.Text := LastEMail;
  if LastRefreshToken.IsEmpty then
    StartEMailEntering
  else
    StartTokenReferesh(LastRefreshToken);
end;

procedure TFraSelfRegistration.StartEMailEntering;
begin
  edtEMail.Visible := true;
  btnCheckEMail.Visible := true;
  btnCheckEMail.Enabled := TFirebaseHelpers.IsEMailAdress(edtEMail.Text);
  lblStatus.Text := rsEnterEMail;
  btnSignIn.Visible := false;
  btnResetPwd.Visible := false;
  btnSignUp.Visible := false;
  edtPassword.Visible := false;
  edtEMail.SetFocus;
end;

procedure TFraSelfRegistration.edtEMailChangeTracking(Sender: TObject);
begin
  if edtPassword.Visible then
  begin
    lblStatus.Text := rsEnterEMail;
    edtPassword.Visible := false;
    btnCheckEMail.Visible := true;
    btnSignUp.Visible := false;
    btnSignIn.Visible := false;
    btnResetPwd.Visible := false;
  end;
  btnCheckEMail.Enabled := TFirebaseHelpers.IsEMailAdress(edtEMail.Text);
end;

procedure TFraSelfRegistration.btnCheckEMailClick(Sender: TObject);
begin
  Assert(assigned(fConfig), 'Config is not initialized');
  fConfig.Auth.FetchProvidersForEMail(edtEmail.Text, OnFetchProviders,
    OnFetchProvidersError);
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnCheckEMail.Enabled := false;
  lblStatus.Text := rsWait;
end;

procedure TFraSelfRegistration.OnFetchProviders(const EMail: string;
  IsRegistered: boolean; Providers: TStrings);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  if IsRegistered then
  begin
    btnSignUp.Visible := false;
    btnSignIn.Visible := true;
    btnSignIn.Enabled := true;
    btnResetPwd.Visible := true;
    btnResetPwd.Enabled := true;
    lblStatus.Text := rsEnterPassword;
  end else begin
    btnSignUp.Visible := true;
    btnSignUp.Enabled := true;
    btnSignIn.Visible := false;
    btnResetPwd.Visible := false;
    lblStatus.Text := rsSetupPassword;
  end;
  edtPassword.Text := '';
  edtPassword.Visible := true;
  edtPassword.SetFocus;
  btnCheckEMail.Visible := false;
end;

procedure TFraSelfRegistration.OnFetchProvidersError(const Info, ErrMsg: string);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  lblStatus.Text := Info + ': ' + ErrMsg;
  btnCheckEMail.Enabled := true;
end;

procedure TFraSelfRegistration.btnSignInClick(Sender: TObject);
begin
  Assert(assigned(fConfig), 'Config is not initialized');
  fConfig.Auth.SignInWithEmailAndPassword(edtEmail.Text, edtPassword.Text,
    OnUserResponse, OnUserError);
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnSignIn.Enabled := false;
  btnResetPwd.Enabled := false;
  lblStatus.Text := rsWait;
end;

procedure TFraSelfRegistration.btnSignUpClick(Sender: TObject);
begin
  Assert(assigned(fConfig), 'Config is not initialized');
  fConfig.Auth.SignUpWithEmailAndPassword(edtEmail.Text, edtPassword.Text,
    OnUserResponse, OnUserError);
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnSignUp.Enabled := false;
  lblStatus.Text := rsWait;
end;

procedure TFraSelfRegistration.btnResetPwdClick(Sender: TObject);
begin
  Assert(assigned(fConfig), 'Config is not initialized');
  fConfig.Auth.SendPasswordResetEMail(edtEMail.Text, OnResetPwd, OnUserError);
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnSignIn.Enabled := false;
  btnResetPwd.Enabled := false;
  lblStatus.Text := rsWait;
end;

procedure TFraSelfRegistration.OnResetPwd(const Info: string; Response: IFirebaseResponse);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  btnSignIn.Enabled := true;
  if Response.StatusOk then
    lblStatus.Text := rsPleaseCheckEMail
  else
    lblStatus.Text := Response.ErrorMsgOrStatusText;
end;

procedure TFraSelfRegistration.StartTokenReferesh(const LastToken: string);
begin
  Assert(assigned(fConfig), 'Config is not initialized');
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  edtEMail.Visible := false;
  btnCheckEMail.Visible := false;
  lblStatus.Text := rsWait;
  btnSignIn.Visible := false;
  btnResetPwd.Visible := false;
  btnSignUp.Visible := false;
  edtPassword.Visible := false;
  fConfig.Auth.RefreshToken(LastToken, OnTokenRefresh, OnUserError);
end;

procedure TFraSelfRegistration.OnTokenRefresh(TokenRefreshed: boolean);
begin
  Assert(assigned(fConfig), 'Config is not initialized');
  if TokenRefreshed then
    fConfig.Auth.GetUserData(OnGetUserData, OnUserError)
  else
    StartEMailEntering;
end;

procedure TFraSelfRegistration.OnGetUserData(FirebaseUserList: TFirebaseUserList);
begin
  if FirebaseUserList.Count = 1 then
    OnUserResponse('AfterTokenRefresh', FirebaseUserList[0])
  else
    StartEMailEntering;
end;

procedure TFraSelfRegistration.OnUserError(const Info, ErrMsg: string);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  lblStatus.Text := Info + ': ' + ErrMsg;
  btnSignIn.Enabled := true;
  btnResetPwd.Enabled := true;
  btnSignUp.Enabled := true;
end;

procedure TFraSelfRegistration.OnUserResponse(const Info: string;
  User: IFirebaseUser);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  lblStatus.Text := rsLoggedIn;
  if assigned(fOnUserLogin) then
    fOnUserLogin(Info, User);
end;

end.
