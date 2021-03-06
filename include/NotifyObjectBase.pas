unit NotifyObjectBase;

interface

uses Variants, CoreClasses, DataFrameEngine;

type
  TNotifyBase = class(TCoreClassInterfacedObject)
  protected
    FNotifyList  : TCoreClassListForObj;
    FSaveRegisted: TCoreClassListForObj;
    procedure DeleteSaveNotifyIntf(p: TNotifyBase);
  public
    constructor Create; virtual;
    destructor Destroy; override;

    procedure RegisterNotify(v: TNotifyBase);
    procedure UnRegisterNotify(v: TNotifyBase);

    // trigger
    procedure DoExecute(const State: Variant); virtual;

    // on execute
    procedure NotifyExecute(Sender: TNotifyBase; const State: Variant); virtual;
  end;

  TNProgressPost = class;
  TNPostExecute  = class;

  TNPostExecuteProc = procedure(Sender: TNPostExecute) of object;

  TNPostExecute = class(TNotifyBase)
  private
    FOwner       : TNProgressPost;
    FDataEng     : TDataFrameEngine;
    ProcessedTime: Double;
  public
    Data1           : TCoreClassObject;
    Data2           : TCoreClassObject;
    Data3           : Variant;
    Data4           : Variant;
    Delay           : Double;
    OnExecute       : TNPostExecuteProc;
    property DataEng: TDataFrameEngine read FDataEng;
    property Owner  : TNProgressPost read FOwner;

    constructor Create; override;
    destructor Destroy; override;
    procedure Execute; virtual;
  end;

  TNPostExecuteClass = class of TNPostExecute;

  TNProgressPost = class(TNotifyBase)
  protected
    FPostProcessIsRun: Boolean;
    FPostExecuteList : TCoreClassListForObj;
    FPostClass       : TNPostExecuteClass;
    FBusy            : Boolean;
    FCurrentExecute  : TNPostExecute;
    FBreakProgress   : Boolean;
    FPaused          : Boolean;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure ResetPost;

    function PostExecute: TNPostExecute; overload;
    function PostExecute(DataEng: TDataFrameEngine): TNPostExecute; overload;
    function PostExecute(DataEng: TDataFrameEngine; OnProc: TNPostExecuteProc): TNPostExecute; overload;
    function PostExecute(Delay: Double): TNPostExecute; overload;
    function PostExecute(Delay: Double; DataEng: TDataFrameEngine): TNPostExecute; overload;
    function PostExecute(Delay: Double; DataEng: TDataFrameEngine; OnProc: TNPostExecuteProc): TNPostExecute; overload;
    function PostExecute(Delay: Double; OnProc: TNPostExecuteProc): TNPostExecute; overload;

    procedure Delete(p: TNPostExecute); overload; virtual;

    procedure Progress(deltaTime: Double); virtual;

    procedure PauseProgress;
    procedure ContinueProgress;

    property Busy: Boolean read FBusy;
    property CurrentExecute: TNPostExecute read FCurrentExecute;
    property PostClass: TNPostExecuteClass read FPostClass write FPostClass;
    property IsPause: Boolean read FPaused;
  end;

implementation


procedure TNotifyBase.DeleteSaveNotifyIntf(p: TNotifyBase);
var
  i: Integer;
begin
  i := 0;
  while i < FSaveRegisted.Count do
    begin
      if FSaveRegisted[i] = TNotifyBase(p) then
          FSaveRegisted.Delete(i)
      else
          Inc(i);
    end;
end;

constructor TNotifyBase.Create;
begin
  inherited Create;
  FNotifyList := TCoreClassListForObj.Create;
  FSaveRegisted := TCoreClassListForObj.Create;
end;

destructor TNotifyBase.Destroy;
begin
  while FSaveRegisted.Count > 0 do
      TNotifyBase(FSaveRegisted[0]).UnRegisterNotify(Self);

  DisposeObject(FSaveRegisted);

  while FNotifyList.Count > 0 do
      UnRegisterNotify(TNotifyBase(FNotifyList[0]));

  DisposeObject(FNotifyList);
  inherited Destroy;
end;

procedure TNotifyBase.RegisterNotify(v: TNotifyBase);
begin
  UnRegisterNotify(v);
  FNotifyList.Add(v);
  v.FSaveRegisted.Add(Self);
end;

procedure TNotifyBase.UnRegisterNotify(v: TNotifyBase);
var
  i: Integer;
begin
  i := 0;
  while i < FNotifyList.Count do
    begin
      if FNotifyList[i] = TNotifyBase(v) then
          FNotifyList.Delete(i)
      else
          Inc(i);
    end;
  v.DeleteSaveNotifyIntf(Self);
end;

procedure TNotifyBase.DoExecute(const State: Variant);
var
  i: Integer;
begin
  i := 0;
  while i < FNotifyList.Count do
    begin
      try
          TNotifyBase(FNotifyList[i]).NotifyExecute(Self, State);
      except
      end;
      Inc(i);
    end;
end;

procedure TNotifyBase.NotifyExecute(Sender: TNotifyBase; const State: Variant);
begin

end;

constructor TNPostExecute.Create;
begin
  inherited Create;
  FDataEng := TDataFrameEngine.Create;
  ProcessedTime := 0;
  Data1 := nil;
  Data2 := nil;
  Data3 := NULL;
  Data4 := NULL;
  Delay := 0;
  OnExecute := nil;
end;

destructor TNPostExecute.Destroy;
var
  i: Integer;
begin
  if FOwner <> nil then
    begin
      if FOwner.CurrentExecute = Self then
          FOwner.FBreakProgress := True;

      i := 0;
      while i < FOwner.FPostExecuteList.Count do
        begin
          if FOwner.FPostExecuteList[i] = Self then
              FOwner.FPostExecuteList.Delete(i)
          else
              Inc(i);
        end;
      FOwner := nil;
    end;
  DisposeObject(FDataEng);
  inherited Destroy;
end;

procedure TNPostExecute.Execute;
begin
  if Assigned(OnExecute) then
    begin
      FDataEng.Reader.index := 0;
      try
          OnExecute(Self);
      except
      end;
    end;
end;

constructor TNProgressPost.Create;
begin
  inherited Create;
  FPostProcessIsRun := False;
  FPostExecuteList := TCoreClassListForObj.Create;
  FPostClass := TNPostExecute;
  FBusy := False;
  FCurrentExecute := nil;
  FBreakProgress := False;
  FPaused := False;
end;

destructor TNProgressPost.Destroy;
begin
  ResetPost;
  DisposeObject(FPostExecuteList);
  inherited Destroy;
end;

procedure TNProgressPost.ResetPost;
var
  i: Integer;
begin
  try
    for i := 0 to FPostExecuteList.Count - 1 do
      begin
        TNPostExecute(FPostExecuteList[i]).FOwner := nil;
        DisposeObject(FPostExecuteList[i]);
      end;

    FPostExecuteList.Clear;
  except
  end;
  FBreakProgress := True;
end;

function TNProgressPost.PostExecute: TNPostExecute;
begin
  Result := FPostClass.Create;
  Result.FOwner := Self;
  FPostExecuteList.Add(Result);
end;

function TNProgressPost.PostExecute(DataEng: TDataFrameEngine): TNPostExecute;
begin
  Result := PostExecute;
  if DataEng <> nil then
      Result.FDataEng.Assign(DataEng);
end;

function TNProgressPost.PostExecute(DataEng: TDataFrameEngine; OnProc: TNPostExecuteProc): TNPostExecute;
begin
  Result := PostExecute(DataEng);
  Result.OnExecute := OnProc;
end;

function TNProgressPost.PostExecute(Delay: Double): TNPostExecute;
begin
  Result := PostExecute;
  Result.Delay := Delay;
end;

function TNProgressPost.PostExecute(Delay: Double; DataEng: TDataFrameEngine): TNPostExecute;
begin
  Result := PostExecute(Delay);
  if DataEng <> nil then
      Result.FDataEng.Assign(DataEng);
end;

function TNProgressPost.PostExecute(Delay: Double; DataEng: TDataFrameEngine; OnProc: TNPostExecuteProc): TNPostExecute;
begin
  Result := PostExecute(Delay, DataEng);
  Result.OnExecute := OnProc;
end;

function TNProgressPost.PostExecute(Delay: Double; OnProc: TNPostExecuteProc): TNPostExecute;
begin
  Result := PostExecute(Delay);
  Result.OnExecute := OnProc;
end;

procedure TNProgressPost.Delete(p: TNPostExecute);
var
  i: Integer;
begin
  i := 0;
  while i < FPostExecuteList.Count do
    begin
      if FPostExecuteList[i] = p then
        begin
          TNPostExecute(FPostExecuteList[i]).FOwner := nil;
          DisposeObject(FPostExecuteList[i]);
          FPostExecuteList.Delete(i);
        end
      else
          Inc(i);
    end;
end;

procedure TNProgressPost.Progress(deltaTime: Double);
var
  i: Integer;
  l: TCoreClassListForObj;
  p: TNPostExecute;
begin
  if FPaused then
      exit;
  if FPostProcessIsRun then
      exit;

  FPostProcessIsRun := True;
  FBreakProgress := False;

  l := TCoreClassListForObj.Create;

  i := 0;
  while i < FPostExecuteList.Count do
    begin
      p := FPostExecuteList[i] as TNPostExecute;
      p.ProcessedTime := p.ProcessedTime + deltaTime;
      if p.ProcessedTime >= p.Delay then
        begin
          l.Add(p);
          FPostExecuteList.Delete(i);
        end
      else
          Inc(i);
    end;

  i := 0;
  while (i < l.Count) do
    begin
      FBusy := True;
      FCurrentExecute := TNPostExecute(l[i]);
      try
          FCurrentExecute.Execute;
      except
      end;
      FBusy := False;
      FCurrentExecute := nil;

      try
          DisposeObject(FCurrentExecute);
      except
      end;
      FCurrentExecute := nil;

      Inc(i);
      if FBreakProgress then
          break;
    end;

  DisposeObject(l);

  FPostProcessIsRun := False;
end;

procedure TNProgressPost.PauseProgress;
begin
  FPaused := True;
end;

procedure TNProgressPost.ContinueProgress;
begin
  FPaused := False;
end;

end.
