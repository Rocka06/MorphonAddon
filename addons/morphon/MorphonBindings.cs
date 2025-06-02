using System;
using Godot;

public partial class MorphonConfigFile : RefCounted
{
    private RefCounted m_Config;

    public MorphonConfigFile()
    {
        m_Config = new();
        m_Config.SetScript(ResourceLoader.Load<Script>("res://addons/morphon/MorphonConfigFile.gd"));
    }

    public void SetValue(string section, string key, Variant value)
    {
        m_Config.Call("set_value", section, key, value);
    }
    public void SetClonedValue(string section, string key, Variant value)
    {
        m_Config.Call("set_cloned_value", section, key, value);
    }
    public Variant GetValue(string section, string key, Variant @default = default)
    {
        return m_Config.Call("get_value", section, key, @default);
    }
    public T GetValue<[MustBeVariant] T>(string section, string key, T @default = default)
    {
        return m_Config.Call("get_value", section, key, Variant.From(@default)).As<T>();
    }
    public bool HasSection(string section)
    {
        return m_Config.Call("has_section", section).As<bool>();
    }
    public bool HasSectionKey(string section, string key)
    {
        return m_Config.Call("has_section_key", section, key).As<bool>();
    }
    public string[] GetSections()
    {
        return m_Config.Call("get_sections").As<string[]>();
    }
    public string[] GetSectionKeys(string section)
    {
        return m_Config.Call("get_section_keys", section).As<string[]>();
    }
    public void EraseSection(string section)
    {
        m_Config.Call("erase_section", section);
    }
    public void EraseSectionKey(string section, string key)
    {
        m_Config.Call("erase_section_key", section);
    }
    public Error Load(string path)
    {
        return m_Config.Call("load", path).As<Error>();
    }
    public Error Save(string path)
    {
        return m_Config.Call("save", path).As<Error>();
    }
    public string EncodeToText()
    {
        return m_Config.Call("encode_to_text").As<string>();
    }
    public Error Parse(string data)
    {
        return m_Config.Call("parse", data).As<Error>();
    }
    public Error LoadEncrypted(string path, byte[] key)
    {
        return m_Config.Call("load_encrypted", path, key).As<Error>();
    }
    public Error LoadEncryptedPass(string path, string password)
    {
        return m_Config.Call("load_encrypted_pass", path, password).As<Error>();
    }
    public Error SaveEncrypted(string path, byte[] key)
    {
        return m_Config.Call("save_encrypted", path, key).As<Error>();
    }
    public Error SaveEncryptedPass(string path, string password)
    {
        return m_Config.Call("save_encrypted_pass", path, password).As<Error>();
    }
    public void Clear()
    {
        m_Config = new();
        Script s = ResourceLoader.Load<Script>("res://addons/morphon/MorphonConfigFile.gd");
        m_Config.SetScript(s);
        GC.Collect();
    }
}

public static class MorhponSerializer
{
    readonly static Script m_Script;

    static MorhponSerializer()
    {
        m_Script = ResourceLoader.Load<Script>("res://addons/morphon/MorphonSerializer.gd");
    }

    public static Variant StrToVar(string str)
    {
        return m_Script.Call("str_to_var", str);
    }

    public static string VarToStr(Variant variant)
    {
        return m_Script.Call("var_to_str", variant).As<string>();
    }

    public static Variant BytesToVar(byte[] bytes)
    {
        return m_Script.Call("bytes_to_var", bytes);
    }

    public static byte[] VarToBytes(Variant variant)
    {
        return m_Script.Call("var_to_bytes", variant).As<byte[]>();
    }
}