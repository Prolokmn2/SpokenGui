# SpokenGui

Lib API:
```lua
local SpokenGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Prolokmn2/SpokenGui/main/loader.lua"))()
local Win = SpokenGui:CreateWindow({Name="Hub", Subtitle="by me", ToggleKey=Enum.KeyCode.RightShift})
local Tab = Win:CreateTab("Main")
Tab:CreateSection("Stuff")
Tab:CreateToggle({Name="Toggle", Default=false, Callback=function(v) end})
Tab:CreateButton({Name="Button", Callback=function() end})
Tab:CreateSlider({Name="Slider", Min=0, Max=100, Increment=1, Default=50, Suffix="x", Callback=function(v) end})
Tab:CreateLabel("text")
local Dd = Tab:CreateDropdown({Name="Pick", Options={"A","B"}, Default="A", Callback=function(v) end}) -- Dd:Set(v) Dd:Get() Dd:Refresh({...})
local Group = Tab:CreateGroup("My Settings", false) -- collapsible list; same Create* methods as a tab
SpokenGui:Notify({Title="Hi", Content="Hello", Duration=3})
```
