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

    /// <summary>
    /// <para>Assigns a value to the specified key of the specified section. If either the section or the key do not exist, they are created. Passing a <see langword="null"/> value deletes the specified key if it exists, and deletes the section if it ends up empty once the key has been removed.</para>
    /// </summary>
    public void SetValue(string section, string key, Variant value)
    {
        m_Config.Call("set_value", section, key, value);
    }

    /// <summary>
    /// Copies and assigns a value to the specified key of the specified section.
    /// If either the section or the key do not exist, they are created.
    /// Passing a null value deletes the specified key if it exists, and deletes the section if it ends up empty once the key has been removed.
    /// </summary>
    public void SetClonedValue(string section, string key, Variant value)
    {
        m_Config.Call("set_cloned_value", section, key, value);
    }

    /// <summary>
    /// <para>Returns the current value for the specified section and key. If either the section or the key do not exist, the method returns the fallback <paramref name="default"/> value. If <paramref name="default"/> is not specified or set to <see langword="null"/>, an error is also raised.</para>
    /// </summary>
    public Variant GetValue(string section, string key, Variant @default = default)
    {
        return m_Config.Call("get_value", section, key, @default);
    }

    /// <summary>
    /// <para>Returns the current value for the specified section and key. If either the section or the key do not exist, the method returns the fallback <paramref name="default"/> value. If <paramref name="default"/> is not specified or set to <see langword="null"/>, an error is also raised.</para>
    /// </summary>
    public T GetValue<[MustBeVariant] T>(string section, string key, T @default = default)
    {
        return m_Config.Call("get_value", section, key, Variant.From(@default)).As<T>();
    }

    /// <summary>
    /// <para>Returns <see langword="true"/> if the specified section exists.</para>
    /// </summary>
    public bool HasSection(string section)
    {
        return m_Config.Call("has_section", section).As<bool>();
    }

    /// <summary>
    /// <para>Returns <see langword="true"/> if the specified section-key pair exists.</para>
    /// </summary>
    public bool HasSectionKey(string section, string key)
    {
        return m_Config.Call("has_section_key", section, key).As<bool>();
    }

    /// <summary>
    /// <para>Returns an array of all defined section identifiers.</para>
    /// </summary>
    public string[] GetSections()
    {
        return m_Config.Call("get_sections").As<string[]>();
    }

    /// <summary>
    /// <para>Returns an array of all defined key identifiers in the specified section. Raises an error and returns an empty array if the section does not exist.</para>
    /// </summary>
    public string[] GetSectionKeys(string section)
    {
        return m_Config.Call("get_section_keys", section).As<string[]>();
    }

    /// <summary>
    /// <para>Deletes the specified section along with all the key-value pairs inside. Raises an error if the section does not exist.</para>
    /// </summary>
    public void EraseSection(string section)
    {
        m_Config.Call("erase_section", section);
    }

    /// <summary>
    /// <para>Deletes the specified key in a section. Raises an error if either the section or the key do not exist.</para>
    /// </summary>
    public void EraseSectionKey(string section, string key)
    {
        m_Config.Call("erase_section_key", section);
    }

    /// <summary>
    /// <para>Loads the config file specified as a parameter. The file's contents are parsed and loaded in the MorphonConfigFile object which the method was called on.</para>
    /// <para>Returns <see cref="Godot.Error.Ok"/> on success, or one of the other <see cref="Godot.Error"/> values if the operation failed.</para>
    /// </summary>
    public Error Load(string path)
    {
        return m_Config.Call("load", path).As<Error>();
    }

    /// <summary>
    /// <para>Saves the contents of the MorphonConfigFile object to the file specified as a parameter. The output file uses a JSON-style structure.</para>
    /// <para>Returns <see cref="Godot.Error.Ok"/> on success, or one of the other <see cref="Godot.Error"/> values if the operation failed.</para>
    /// </summary>
    public Error Save(string path)
    {
        return m_Config.Call("save", path).As<Error>();
    }

    /// <summary>
    /// <para>Obtain the text version of this config file (the same text that would be written to a file).</para>
    /// </summary>
    public string EncodeToText()
    {
        return m_Config.Call("encode_to_text").As<string>();
    }

    /// <summary>
    /// <para>Parses the passed string as the contents of a config file. The string is parsed and loaded in the MorphonConfigFile object which the method was called on.</para>
    /// <para>Returns <see cref="Godot.Error.Ok"/> on success, or one of the other <see cref="Godot.Error"/> values if the operation failed.</para>
    /// </summary>
    public Error Parse(string data)
    {
        return m_Config.Call("parse", data).As<Error>();
    }

    /// <summary>
    /// <para>Loads the encrypted config file specified as a parameter, using the provided <paramref name="key"/> to decrypt it. The file's contents are parsed and loaded in the MorphonConfigFile object which the method was called on.</para>
    /// <para>Returns <see cref="Godot.Error.Ok"/> on success, or one of the other <see cref="Godot.Error"/> values if the operation failed.</para>
    /// </summary>
    public Error LoadEncrypted(string path, byte[] key)
    {
        return m_Config.Call("load_encrypted", path, key).As<Error>();
    }

    /// <summary>
    /// <para>Loads the encrypted config file specified as a parameter, using the provided <paramref name="password"/> to decrypt it. The file's contents are parsed and loaded in the MorphonConfigFile object which the method was called on.</para>
    /// <para>Returns <see cref="Godot.Error.Ok"/> on success, or one of the other <see cref="Godot.Error"/> values if the operation failed.</para>
    /// </summary>
    public Error LoadEncryptedPass(string path, string password)
    {
        return m_Config.Call("load_encrypted_pass", path, password).As<Error>();
    }

    /// <summary>
    /// <para>Saves the contents of the MorphonConfigFile object to the AES-256 encrypted file specified as a parameter, using the provided <paramref name="key"/> to encrypt it. The output file uses an JSON-style structure.</para>
    /// <para>Returns <see cref="Godot.Error.Ok"/> on success, or one of the other <see cref="Godot.Error"/> values if the operation failed.</para>
    /// </summary>
    public Error SaveEncrypted(string path, byte[] key)
    {
        return m_Config.Call("save_encrypted", path, key).As<Error>();
    }

    /// <summary>
    /// <para>Saves the contents of the MorphonConfigFile object to the AES-256 encrypted file specified as a parameter, using the provided <paramref name="password"/> to encrypt it. The output file uses an JSON-style structure.</para>
    /// <para>Returns <see cref="Godot.Error.Ok"/> on success, or one of the other <see cref="Godot.Error"/> values if the operation failed.</para>
    /// </summary>
    public Error SaveEncryptedPass(string path, string password)
    {
        return m_Config.Call("save_encrypted_pass", path, password).As<Error>();
    }

    /// <summary>
    /// <para>Removes the entire contents of the config.</para>
    /// </summary>
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

    /// <summary>
    /// Converts a formatted string that was returned by MorphonSerializer.VarToStr() to the original Variant
    /// </summary>
    public static Variant StrToVar(string str)
    {
        return m_Script.Call("str_to_var", str);
    }

    /// <summary>
    /// Converts a Variant to a formatted String that can then be parsed using MorphonSerializer.StrToVar().
    /// </summary>
    public static string VarToStr(Variant variant)
    {
        return m_Script.Call("var_to_str", variant).As<string>();
    }

    /// <summary>
    /// Decodes a PackedByteArray back to a Variant value.
    /// </summary>
    public static Variant BytesToVar(byte[] bytes)
    {
        return m_Script.Call("bytes_to_var", bytes);
    }

    /// <summary>
    /// Encodes a Variant value to a PackedByteArray. Deserialization can be done with MorphonSerializer.BytesToVar().
    /// </summary>
    public static byte[] VarToBytes(Variant variant)
    {
        return m_Script.Call("var_to_bytes", variant).As<byte[]>();
    }
}