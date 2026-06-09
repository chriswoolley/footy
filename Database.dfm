object dmData: TdmData
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  OnDestroy = DataModuleDestroy
  Left = 789
  Top = 547
  Height = 258
  Width = 604
  object dbDream: TOraSession
    Username = 'dream'
    Password = 'tesco'
    Server = 'OFFICE'
    LoginPrompt = False
    Left = 32
    Top = 24
  end
end
