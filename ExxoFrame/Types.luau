--!strict
--!native
--!optimize 2
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Library = ReplicatedStorage:WaitForChild("Library")

export type PlayerGUI = typeof(game:GetService("StarterGui"))
export type MainUI = typeof(game:GetService("StarterGui"):WaitForChild("MainUI"))
export type MainFrames = typeof(game:GetService("StarterGui"):WaitForChild("MainUI"):WaitForChild("MainFrames"))
export type HUD = typeof(game:GetService("StarterGui"):WaitForChild("HUD"))
export type Inset = typeof(game:GetService("StarterGui"):WaitForChild("Inset"))

export type PlayerData = typeof(require(script.Parent.DefaultData))
export type PlayerType = typeof(require(Library.PlayerUtil))
export type InstanceType = typeof(require(Library.InstanceUtil))
export type OutputType = typeof(require(Library.Output))
export type NumberType = typeof(require(Library.NumberUtil))
export type SoundType = typeof(require(Library.SoundUtil))
export type TableType = typeof(require(Library.TableUtil))
export type FrameType = typeof(require(Library.FrameUtil))
export type CollisionGroupsType = typeof(require(Library.CollisionGroups))
export type GlobalSettingsType = typeof(require(Library.GlobalSettings))
export type EffectsType = typeof(require(Library.EffectsUtil))
export type ColorsType = typeof(require(Library.Colors))
export type NewPlayerType = typeof(require(game:GetService("ServerScriptService"):WaitForChild("Core"):WaitForChild("NewPlayer")))
export type FramesControllerType = typeof(require(game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"):WaitForChild("Cores"):WaitForChild("FramesController")))

type Connection = {
    Disconnect: (self: Connection) -> (),
    Connected: boolean,
}

export type ClientBridge = {
    Fire: (self: ClientBridge, Player: Player, ModuleName: string, FunctionName: string, ...any) -> (),
    FireAll: (self: ClientBridge, ModuleName: string, FunctionName: string, ...any) -> (),
    FireSpecific: (self: ClientBridge, PlayersToFire: { Player }, ModuleName: string, FunctionName: string, ...any) -> (),
    FireExcept: (self: ClientBridge, PlayersToNotFire: { Player }, ModuleName: string, FunctionName: string, ...any) -> (),
    FireSelf: (self: ClientBridge, ModuleName: string, FunctionName: string, ...any) -> (),
}

export type ServerBridge = {
    Fire: (self: ServerBridge, ModuleName: string, FunctionName: string, ...any) -> (),
    FireSelf: (self: ServerBridge, ModuleName: string, FunctionName: string, ...any) -> (),
}

export type Loop = {
    Fire: (self: Loop) -> (),
    Connect: (self: Loop, func: () -> ()) -> Connection,
    Disconnect: (self: Loop) -> (),
}

export type CharacterConnection = Loop

export type ExxoFrame = {
    GameVersion: number,
    StartTime: number,

    Server: ServerBridge,
    Client: ClientBridge,

    FastLoop: Loop,
    HalfLoop: Loop,
    SecondLoop: Loop,
    MinuteLoop: Loop,

    Player: PlayerType,
    Instance: InstanceType,
    Output: OutputType,
    Number: NumberType,
    Sound: SoundType,
    Table: TableType,
    Frame: FrameType,
    CollisionGroups: CollisionGroupsType,
    GlobalSettings: GlobalSettingsType,
    Effects: EffectsType,
    Colors: ColorsType,
    FramesController: FramesControllerType,

    PlayerGUI: PlayerGUI,
    MainUI: MainUI,
    MainFrames: MainFrames,
    HUD: HUD,
    Inset: Inset,
    
    ReferenceModules: { [string]: any },
    Services: { [string]: any },
    Components: { [string]: any },
    UserFrames: { [string]: any },
    Animations: { [string]: any },
    Data: PlayerData,

    GetCharacter: () -> Character?,
    GetMouse: () -> Mouse?,
    GetDevice: () -> "CONSOLE" | "PC" | "MOBILE",
    CharacterAdded: CharacterConnection,
    CharacterRemoved: CharacterConnection,

    IsPremium: () -> boolean,
    ServerShutdown: boolean,

    NewPlayer: NewPlayerType,
    ThreadHandler: (Function: () -> ()) -> (),
}

return nil