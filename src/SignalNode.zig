const std = @import("std");
const godot = @import("godot");
const Vec2 = godot.Vector2;
const Vec3 = godot.Vector3;
const Self = @This();

base: godot.Control, //this makes @Self a valid gdextension class
color_rect: godot.ColorRect = undefined,

pub fn _bind_methods() void {
    godot.registerSignal(Self, "signal1", &[_]godot.PropertyInfo{
        godot.PropertyInfo.init(godot.GDEXTENSION_VARIANT_TYPE_STRING, godot.StringName.initFromLatin1Chars("name")),
        godot.PropertyInfo.init(godot.GDEXTENSION_VARIANT_TYPE_VECTOR3, godot.StringName.initFromLatin1Chars("position")),
    });

    godot.registerSignal(Self, "signal2", &.{});
    godot.registerSignal(Self, "signal3", &.{});
}

pub fn _enter_tree(self: *Self) void {
    if (godot.Engine.getSingleton().isEditorHint()) return;

    var signal1_btn = godot.initButton();
    signal1_btn.setPosition(Vec2.new(100, 20), false);
    signal1_btn.setSize(Vec2.new(100, 50), false);
    signal1_btn.setText("Signal1");
    self.base.addChild(signal1_btn, false, godot.Node.INTERNAL_MODE_DISABLED);

    var signal2_btn = godot.initButton();
    signal2_btn.setPosition(Vec2.new(250, 20), false);
    signal2_btn.setSize(Vec2.new(100, 50), false);
    signal2_btn.setText("Signal2");
    self.base.addChild(signal2_btn, false, godot.Node.INTERNAL_MODE_DISABLED);

    var signal3_btn = godot.initButton();
    signal3_btn.setPosition(Vec2.new(400, 20), false);
    signal3_btn.setSize(Vec2.new(100, 50), false);
    signal3_btn.setText("Signal3");
    self.base.addChild(signal3_btn, false, godot.Node.INTERNAL_MODE_DISABLED);

    self.color_rect = godot.initColorRect();
    self.color_rect.setPosition(Vec2.new(400, 400), false);
    self.color_rect.setSize(Vec2.new(100, 100), false);
    self.color_rect.setColor(godot.Color.initFromF64F64F64F64(1, 0, 0, 1));
    self.base.addChild(self.color_rect, false, godot.Node.INTERNAL_MODE_DISABLED);

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

pub fn onSignal1(_: *Self, name: godot.StringName, position: godot.Vector3) void {
    var buf: [256]u8 = undefined;
    const n = godot.stringNameToAscii(name, &buf);
    std.debug.print("signal1 received : name = {s} position={any}\n", .{ n, position });
}

pub fn onSignal2(self: *Self) void {
    self.color_rect.setColor(godot.Color.initFromF64F64F64F64(0, 1, 0, 1));
}

pub fn onSignal3(self: *Self) void {
    self.color_rect.setColor(godot.Color.initFromF64F64F64F64(1, 0, 0, 1));
}

pub fn emitSignal1(self: *Self) void {
    _ = self.base.emitSignal("signal1", .{ godot.String.initFromLatin1Chars("test_signal_name"), Vec3.new(123, 321, 333) });
}
pub fn emitSignal2(self: *Self) void {
    _ = self.base.emitSignal("signal2", .{});
}
pub fn emitSignal3(self: *Self) void {
    _ = self.base.emitSignal("signal3", .{});
}
