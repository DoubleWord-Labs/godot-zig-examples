const std = @import("std");
const godot = @import("godot");
const Vec2 = godot.Vector2;
const Self = @This();

base: godot.Control,
sprite: godot.Sprite2D,

pub fn _enter_tree(self: *Self) void {
    if (godot.Engine.getSingleton().isEditorHint()) return;

    var normal_btn = godot.Button.init();
    self.base.addChild(normal_btn, false, godot.Node.INTERNAL_MODE_DISABLED);
    normal_btn.setPosition(Vec2.new(100, 20), false);
    normal_btn.setSize(Vec2.new(100, 50), false);
    normal_btn.setText("Press Me");

    var toggle_btn = godot.CheckBox.init();
    self.base.addChild(toggle_btn, false, godot.Node.INTERNAL_MODE_DISABLED);
    toggle_btn.setPosition(Vec2.new(320, 20), false);
    toggle_btn.setSize(Vec2.new(100, 50), false);
    toggle_btn.setText("Toggle Me");

    godot.connect(toggle_btn, "toggled", self, "on_toggled");
    godot.connect(normal_btn, "pressed", self, "on_pressed");

    const resource_loader = godot.ResourceLoader.getSingleton();
    const res_name = godot.String.initFromLatin1Chars("res://textures/logo.png");
    const texture = resource_loader.load(res_name, "", godot.ResourceLoader.CACHE_MODE_REUSE);
    if (texture) |tex| {
        defer _ = godot.unreference(tex);
        self.sprite = godot.Sprite2D.init();
        self.sprite.setTexture(tex);
        self.sprite.setPosition(Vec2.new(400, 300));
        self.sprite.setScale(Vec2.new(0.6, 0.6));
        self.base.addChild(self.sprite, false, godot.Node.INTERNAL_MODE_DISABLED);
    }
}

pub fn _exit_tree(self: *Self) void {
    _ = self;
}

pub fn on_pressed(self: *Self) void {
    _ = self;
    std.debug.print("on_pressed \n", .{});
}

pub fn on_toggled(self: *Self, toggled_on: bool) void {
    _ = self;
    std.debug.print("on_toggled {any}\n", .{toggled_on});
}
