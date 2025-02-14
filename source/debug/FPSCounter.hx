package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
//import openfl.text.Font;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;
import lime.app.Application;
import states.MainMenuState;

/**
    The FPS class provides an easy-to-use monitor to display
    the current frame rate of an OpenFL project
**/
#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end
class FPSCounter extends TextField
{
    /**
        The current frame rate, expressed using frames-per-second
    **/
    public var currentFPS(default, null):Int;

    /**
        The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
    **/
    public var memoryMegas(get, never):Float;
    
	public var memoryPeakMegas(get, never):Float;
    private var memoryPeak:Float = 0;

    @:noCompletion private var times:Array<Float>;

    public var os:String = '';

    public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
    {
        super();

        // Load the custom font
        //var font:Font = new Font('assets/fonts/cnfont.ttf'); // 确保路径正确

        #if !officialBuild
        if (LimeSystem.platformName == LimeSystem.platformVersion || LimeSystem.platformVersion == null)
            os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end;
        else
            os = '\nOS: ${LimeSystem.platformName}' #if cpp + ' ${getArch() != 'Unknown' ? getArch() : ''}' #end + ' - ${LimeSystem.platformVersion}';
        #end

        positionFPS(x, y);

        currentFPS = 0;
        selectable = false;
        mouseEnabled = false;

        // Set the font and text format
        // defaultTextFormat = new TextFormat(font.fontName, (ClientPrefs.data.fpsCounterSize), color); // 使用自定义字体
        defaultTextFormat = new TextFormat("_sans", (ClientPrefs.data.fpsCounterSize), color);
        width = FlxG.width;
        multiline = true;
        text = "Loading...";

        times = [];
    }

    var deltaTimeout:Float = 0.0;

    // Event Handlers
    private override function __enterFrame(deltaTime:Float):Void
    {
        final now:Float = haxe.Timer.stamp() * 1000;
        times.push(now);
        while (times[0] < now - 1000) times.shift();
        // prevents the overlay from updating every frame, why would you need to anyways @crowplexus
        if (deltaTimeout < 50) {
            deltaTimeout += deltaTime;
            return;
        }

        currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;        
        updateText();
        deltaTimeout = 0.0;
    }

    public dynamic function updateText():Void // so people can override it in hscript
    {
		if (memoryMegas > memoryPeak) {
            memoryPeak = memoryMegas;
        }

        text = 
        'FPS: $currentFPS' + 
        '\nMemory: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}'+' / ${flixel.util.FlxStringUtil.formatBytes(memoryPeak)}' + 
		os ;
        if(ClientPrefs.data.exgameversion) text += '\nMintRain Engine v${Application.current.meta.get('version')} \nPsych Engine v${MainMenuState.psychEngineVersion.trim()}';

        textColor = 0xFFFFFFFF;
        if (currentFPS < FlxG.drawFramerate * 0.5)
            textColor = 0xFFFF0000;
    }

    inline function get_memoryMegas():Float
    return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);

	inline function get_memoryPeakMegas():Float
        return memoryPeak;

    public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1){
        scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
        x = FlxG.game.x + X;
        y = FlxG.game.y + Y;
    }

    #if cpp
    #if windows
    @:functionCode('
        SYSTEM_INFO osInfo;

        GetSystemInfo(&osInfo);

        switch(osInfo.wProcessorArchitecture)
        {
            case 9:
                return ::String("x86_64");
            case 5:
                return ::String("ARMHF");
            case 12:
                return ::String("ARM64");
            case 6:
                return ::String("IA-64");
            case 0:
                return ::String("x86");
            default:
                return ::String("Unknown");
        }
    ')
    #elseif (ios || mac)
    @:functionCode('
        const NXArchInfo *archInfo = NXGetLocalArchInfo();
        return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
    ')
    #else
    @:functionCode('
        struct utsname osInfo{};
        uname(&osInfo);
        return ::String(osInfo.machine);
    ')
    #end
    @:noCompletion
    private function getArch():String
    {
        return "Unknown";
    }
    #end
}