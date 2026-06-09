object FrmLogin: TFrmLogin
  Left = 743
  Top = 430
  BorderStyle = bsDialog
  Caption = 'Login'
  ClientHeight = 160
  ClientWidth = 298
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblUsername: TLabel
    Left = 8
    Top = 12
    Width = 48
    Height = 13
    Caption = 'Username'
  end
  object lblPassword: TLabel
    Left = 8
    Top = 36
    Width = 46
    Height = 13
    Caption = 'Password'
  end
  object lblEMail: TLabel
    Left = 8
    Top = 60
    Width = 29
    Height = 13
    Caption = 'E-Mail'
  end
  object Label1: TLabel
    Left = 8
    Top = 138
    Width = 71
    Height = 13
    Caption = 'New Password'
  end
  object Label2: TLabel
    Left = 8
    Top = 84
    Width = 27
    Height = 13
    Caption = 'Team'
  end
  object Label3: TLabel
    Left = 8
    Top = 116
    Width = 73
    Height = 13
    Caption = 'New Username'
  end
  object btnOK: TButton
    Left = 216
    Top = 8
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 4
    OnClick = btnOKClick
  end
  object btnCancel: TButton
    Left = 216
    Top = 40
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 7
    OnClick = btnCancelClick
  end
  object edtUsername: TEdit
    Left = 88
    Top = 8
    Width = 121
    Height = 21
    TabOrder = 0
    OnKeyPress = edtUsernameKeyPress
  end
  object edtPassword: TEdit
    Left = 88
    Top = 32
    Width = 121
    Height = 21
    PasswordChar = #174
    TabOrder = 1
    OnKeyPress = edtPasswordKeyPress
  end
  object edtEMail: TEdit
    Left = 88
    Top = 56
    Width = 121
    Height = 21
    TabOrder = 2
  end
  object edtPassword2: TEdit
    Left = 88
    Top = 134
    Width = 121
    Height = 21
    PasswordChar = #174
    TabOrder = 6
  end
  object Panel1: TPanel
    Left = 8
    Top = 104
    Width = 201
    Height = 2
    TabOrder = 8
  end
  object edtTeam: TEdit
    Left = 88
    Top = 80
    Width = 121
    Height = 21
    TabOrder = 3
  end
  object edtUsername2: TEdit
    Left = 88
    Top = 112
    Width = 121
    Height = 21
    TabOrder = 5
    OnKeyPress = edtUsernameKeyPress
  end
end
