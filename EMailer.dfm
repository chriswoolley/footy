object Form1: TForm1
  Left = 338
  Top = 238
  Width = 558
  Height = 319
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 136
    Width = 32
    Height = 13
    Caption = 'Label1'
  end
  object Label2: TLabel
    Left = 8
    Top = 160
    Width = 32
    Height = 13
    Caption = 'Label2'
  end
  object btnHeader: TButton
    Left = 8
    Top = 40
    Width = 75
    Height = 25
    Caption = 'btnHeader'
    TabOrder = 0
    OnClick = btnHeaderClick
  end
  object ListBox1: TListBox
    Left = 88
    Top = 8
    Width = 453
    Height = 270
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    MultiSelect = True
    TabOrder = 1
  end
  object btnConnect: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'btnConnect'
    TabOrder = 2
    OnClick = btnConnectClick
  end
  object btnDisconnect: TButton
    Left = 8
    Top = 104
    Width = 75
    Height = 25
    Caption = 'btnDisconnect'
    TabOrder = 3
    OnClick = btnDisconnectClick
  end
  object btnDelete: TButton
    Left = 8
    Top = 72
    Width = 75
    Height = 25
    Caption = 'btnDelete'
    TabOrder = 4
    OnClick = btnDeleteClick
  end
  object Edit1: TEdit
    Left = 8
    Top = 176
    Width = 73
    Height = 21
    TabOrder = 5
    Text = '100'
  end
  object SMTP: TIdSMTP
    MaxLineAction = maException
    Host = 'smtp.moatingodseye.co.uk'
    Port = 25
    AuthenticationType = atLogin
    Password = 'really'
    Username = 'beasty'
    Left = 112
    Top = 16
  end
  object POP: TIdPOP3
    MaxLineAction = maException
    Host = '90.0.0.77'
    Password = '2767'
    Username = 'all'
    Left = 112
    Top = 64
  end
  object POPMsg: TIdMessage
    AttachmentEncoding = 'MIME'
    BccList = <>
    CCList = <>
    Encoding = meMIME
    Recipients = <>
    ReplyTo = <>
    Left = 160
    Top = 64
  end
  object SMTPMsg: TIdMessage
    AttachmentEncoding = 'MIME'
    BccList = <>
    CCList = <>
    Encoding = meMIME
    Recipients = <>
    ReplyTo = <>
    Left = 160
    Top = 16
  end
end
