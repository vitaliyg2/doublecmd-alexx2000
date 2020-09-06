unit uRegExpr;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LConvEncoding, uConvEncoding, RegExpr, uRegExprA, uRegExprW;

type
  TRegExprType = (retAnsi, retUtf16le, retUtf8);

type

  { TRegExprEx }

  TRegExprEx = class
  private
    FEncoding: String;
    FRegExpA: TRegExpr;
    FRegExpW: TRegExprW;
    FType: TRegExprType;
    procedure SetExpression(AValue: String);
    function GetMatchLen(Idx : Integer): PtrInt;
    function GetMatchPos(Idx : Integer): PtrInt;
  public
    constructor Create(const AEncoding: String = EncodingDefault);
    destructor Destroy; override;
    function Exec(AOffset: UIntPtr = 1): Boolean;
    procedure ChangeEncoding(const AEncoding: String);
    procedure SetInputString(AInputString : Pointer; ALength : UIntPtr);
  public
    property Expression : String write SetExpression;
    property MatchPos [Idx : Integer] : PtrInt read GetMatchPos;
    property MatchLen [Idx : Integer] : PtrInt read GetMatchLen;
  end;

implementation

uses
  LazUTF8;

{ TRegExprEx }

procedure TRegExprEx.SetExpression(AValue: String);
begin
  case FType of
    retUtf16le: FRegExpW.Expression:= UTF8ToUTF16(AValue);
    retAnsi, retUtf8:    FRegExpA.Expression:= ConvertEncoding(AValue, EncodingUTF8, FEncoding);
  end;
end;

function TRegExprEx.GetMatchLen(Idx: integer): PtrInt;
begin
  case FType of
    retAnsi, retUtf8:    Result:= FRegExpA.MatchLen[Idx];
    retUtf16le: Result:= FRegExpW.MatchLen[Idx] * SizeOf(WideChar);
  end;
end;

function TRegExprEx.GetMatchPos(Idx: integer): PtrInt;
begin
  case FType of
    retAnsi, retUtf8:    Result:= FRegExpA.MatchPos[Idx];
    retUtf16le: Result:= FRegExpW.MatchPos[Idx] * SizeOf(WideChar);
  end;
end;

constructor TRegExprEx.Create(const AEncoding: String);
begin
  FRegExpW:= TRegExprW.Create;
  FRegExpA:= TRegExpr.Create(AEncoding);
end;

destructor TRegExprEx.Destroy;
begin
  FRegExpA.Free;
  FRegExpW.Free;
  inherited Destroy;
end;

function TRegExprEx.Exec(AOffset: UIntPtr): Boolean;
begin
  case FType of
    retAnsi, retUtf8:    Result:= FRegExpA.Exec(AOffset);
    retUtf16le: Result:= FRegExpW.Exec((AOffset + 1) div SizeOf(WideChar));
  end;
end;

procedure TRegExprEx.ChangeEncoding(const AEncoding: String);
begin
  FEncoding:= NormalizeEncoding(AEncoding);
  if FEncoding = EncodingUTF16LE then
    FType:= retUtf16le
  else if (FEncoding = EncodingUTF8) or (FEncoding = EncodingUTF8BOM) then
    FType:= retUtf8
  else begin
    FType:= retAnsi;
    FRegExpA.ChangeEncoding(FEncoding);
  end;
end;

procedure TRegExprEx.SetInputString(AInputString: Pointer; ALength: UIntPtr);
begin
  case FType of
    retAnsi, retUtf8:    FRegExpA.SetInputString(AInputString, ALength);
    retUtf16le: FRegExpW.SetInputString(AInputString, ALength div SizeOf(WideChar));
  end;
end;

end.

