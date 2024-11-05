
const SColor col_bg = SColor(125,0,0,0);
const SColor col_title_bg = SColor(100,0,0,0);

Vec2f dim = Vec2f(200, 100);
Vec2f title_dim = Vec2f(0, 20); // x represents additional width here

Vec2f padding = Vec2f(4,2);

Vec2f sc = getDriver().getScreenCenterPos();
Vec2f pos = sc - dim/2;

Vec2f arrow_point_pos;

string title = "";
string text = "";


void renderTutorial(CRules@ this)
{
    CPlayer@ local = getLocalPlayer(); // null check is in GameHelp.as onRender()
    CBlob@ blob = getLocalPlayerBlob();

    GUI::DrawRectangle(pos, pos+dim, col_bg);
    GUI::DrawRectangle(pos - Vec2f(title_dim.x, 0), pos + Vec2f(dim.x,0) + title_dim, col_title_bg);

    GUI::SetFont("menu");
    GUI::DrawTextCentered(title, pos + Vec2f(dim.x/2, title_dim.y/2) - Vec2f(2,1), color_white);

    Vec2f text_pos = pos + Vec2f(padding.x, title_dim.y + padding.y);
    Vec2f text_endpos = pos + dim - padding;

    GUI::DrawText(text, text_pos, color_white);
}

void setWindowPos(Vec2f new_pos, f32 lerp = 0.5f)
{
    pos = Vec2f_lerp(pos, new_pos, lerp);
}

void setWindowDim(Vec2f new_dim, f32 lerp = 0.5f)
{
    dim = Vec2f_lerp(dim, new_dim, lerp);
}

void setText(string new_text)
{
    text = new_text;
}

void setTitle(string new_title)
{
    title = new_title;
}