const Self = @This();

base: Control, //this makes @Self a valid gdextension class
color_rect: ColorRect = undefined,

pub fn _bind_methods() void {
    godot.registerSignal(Self, "signal1", &[_]PropertyInfo{
        PropertyInfo.init(godot.c.GDEXTENSION_VARIANT_TYPE_STRING, StringName.initFromLatin1Chars("name")),
        PropertyInfo.init(godot.c.GDEXTENSION_VARIANT_TYPE_VECTOR3, StringName.initFromLatin1Chars("position")),
    });

    godot.registerSignal(Self, "signal2", &.{});
    godot.registerSignal(Self, "signal3", &.{});
}

pub fn _enter_tree(self: *Self) void {
    if (Engine.getSingleton().isEditorHint()) return;

    var signal1_btn = Button.init();
    signal1_btn.setPosition(Vector2.new(100, 20), false);
    signal1_btn.setSize(Vector2.new(100, 50), false);
    signal1_btn.setText("Signal1");
    self.base.addChild(signal1_btn, false, Node.INTERNAL_MODE_DISABLED);

    var signal2_btn = Button.init();
    signal2_btn.setPosition(Vector2.new(250, 20), false);
    signal2_btn.setSize(Vector2.new(100, 50), false);
    signal2_btn.setText("Signal2");
    self.base.addChild(signal2_btn, false, Node.INTERNAL_MODE_DISABLED);

    var signal3_btn = Button.init();
    signal3_btn.setPosition(Vector2.new(400, 20), false);
    signal3_btn.setSize(Vector2.new(100, 50), false);
    signal3_btn.setText("Signal3");
    self.base.addChild(signal3_btn, false, Node.INTERNAL_MODE_DISABLED);

    self.color_rect = ColorRect.init();
    self.color_rect.setPosition(Vector2.new(400, 400), false);
    self.color_rect.setSize(Vector2.new(100, 100), false);
    self.color_rect.setColor(Color.initFromF64F64F64F64(1, 0, 0, 1));
    self.base.addChild(self.color_rect, false, Node.INTERNAL_MODE_DISABLED);

    godot.connect(signal1_btn, "pressed", self, "emitSignal1");
    godot.connect(signal2_btn, "pressed", self, "emitSignal2");
    godot.connect(signal3_btn, "pressed", self, "emitSignal3");
    godot.connect(self.base, "signal1", self, "onSignal1");
    godot.connect(self.base, "signal2", self, "onSignal2");
    godot.connect(self.base, "signal3", self, "onSignal3");
}

pub fn _exit_tree(self: *Self) void {
    _ = self;
}

pub fn onSignal1(_: *Self, name: StringName, position: Vector3) void {
    var buf: [256]u8 = undefined;
    const n = godot.stringNameToAscii(name, &buf);
    std.debug.print("signal1 received : name = {s} position={any}\n", .{ n, position });
}

pub fn onSignal2(self: *Self) void {
    self.color_rect.setColor(Color.initFromF64F64F64F64(0, 1, 0, 1));
}

pub fn onSignal3(self: *Self) void {
    self.color_rect.setColor(Color.initFromF64F64F64F64(1, 0, 0, 1));
}

pub fn emitSignal1(self: *Self) void {
    _ = self.base.emitSignal("signal1", .{ String.initFromLatin1Chars("test_signal_name"), Vector3.new(123, 321, 333) });
}
pub fn emitSignal2(self: *Self) void {
    _ = self.base.emitSignal("signal2", .{});
}
pub fn emitSignal3(self: *Self) void {
    _ = self.base.emitSignal("signal3", .{});
}

const std = @import("std");
const godot = @import("godot");
const Button = godot.core.Button;
const Color = godot.core.Color;
const ColorRect = godot.core.ColorRect;
const Control = godot.core.Control;
const Engine = godot.core.Engine;
const Node = godot.core.Node;
const PropertyInfo = godot.PropertyInfo;
const String = godot.core.String;
const StringName = godot.core.StringName;
const Vector2 = godot.Vector2;
const Vector3 = godot.Vector3;
