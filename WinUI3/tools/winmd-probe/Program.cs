using System.Collections.Immutable;
using System.Reflection;
using System.Reflection.Metadata;
using System.Reflection.PortableExecutable;

// Reads Windows Runtime metadata (.winmd / projection .dll) and dumps types,
// implemented interfaces and public method signatures. Exists because API
// claims in this tutorial can be checked without a Windows SDK, cppwinrt or
// a build — System.Reflection.Metadata is in the base class library.
//
// usage: winmd-probe <file.winmd> [TypeFilter] [--types-only]
//        winmd-probe --find <TypeName> [searchDir]

var positional = new List<string>();
bool typesOnly = false;
string? find = null;

for (int i = 0; i < args.Length; i++)
{
    string a = args[i];
    if (a == "--types-only") typesOnly = true;
    else if (a == "--find")
    {
        if (i + 1 >= args.Length) { Console.Error.WriteLine("--find needs a type name"); return 1; }
        find = args[++i];
    }
    else if (a is "-h" or "--help") { Usage(); return 0; }
    else positional.Add(a);
}

if (find is not null)
{
    string root = positional.Count > 0
        ? positional[0]
        : Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".nuget", "packages");
    if (!Directory.Exists(root)) { Console.Error.WriteLine($"not found: {root}"); return 1; }
    Console.Error.WriteLine($"scanning {root} for *{find}* ...");
    int hits = 0;
    foreach (var file in Directory.EnumerateFiles(root, "*.winmd", SearchOption.AllDirectories)
                         .Concat(Directory.EnumerateFiles(root, "Microsoft.WinUI.dll", SearchOption.AllDirectories)))
    {
        foreach (var t in TypesIn(file, find))
        {
            Console.WriteLine($"{file}\n    {t}");
            hits++;
        }
    }
    if (hits == 0) Console.Error.WriteLine("no match");
    return hits == 0 ? 2 : 0;
}

if (positional.Count < 1) { Usage(); return 1; }

string path = positional[0];
string filter = positional.Count > 1 ? positional[1] : "";
if (!Dump(path, filter, typesOnly)) return 1;
return 0;

void Usage() => Console.WriteLine("""
    usage: winmd-probe <file.winmd> [TypeFilter] [--types-only]
           winmd-probe --find <TypeName> [searchDir]

      TypeFilter    substring match on namespace-qualified type name
      --types-only  print type names without members
      --find        scan *.winmd (default: the NuGet package cache) for a type,
                    and report which metadata file declares it
    """);

static List<string> TypesIn(string file, string filter)
{
    var hits = new List<string>();
    try
    {
        using var fs = File.OpenRead(file);
        using var pe = new PEReader(fs);
        if (!pe.HasMetadata) return hits;
        var mr = pe.GetMetadataReader();
        foreach (var th in mr.TypeDefinitions)
        {
            string full = Full(mr, mr.GetTypeDefinition(th));
            if (full.Contains(filter, StringComparison.OrdinalIgnoreCase)) hits.Add(full);
        }
    }
    catch (BadImageFormatException) { }
    catch (IOException) { }
    return hits;
}

static bool Dump(string path, string filter, bool typesOnly)
{
    if (!File.Exists(path)) { Console.Error.WriteLine($"not found: {path}"); return false; }

    using var fs = File.OpenRead(path);
    using var pe = new PEReader(fs);
    if (!pe.HasMetadata) { Console.Error.WriteLine("no metadata"); return false; }

    var mr = pe.GetMetadataReader();
    var sig = new StringProvider();

    int shown = 0;
    foreach (var th in mr.TypeDefinitions)
    {
        var td = mr.GetTypeDefinition(th);
        string full = Full(mr, td);
        if (filter.Length > 0 && !full.Contains(filter, StringComparison.OrdinalIgnoreCase)) continue;
        shown++;

        bool isInterface = td.Attributes.HasFlag(TypeAttributes.Interface);
        Console.WriteLine($"{(isInterface ? "interface" : "class")} {full}");
        if (typesOnly) continue;

        foreach (var iih in td.GetInterfaceImplementations())
            Console.WriteLine($"    implements {NameOf(mr, mr.GetInterfaceImplementation(iih).Interface, sig)}");

        foreach (var mh in td.GetMethods())
        {
            var md = mr.GetMethodDefinition(mh);
            if (md.Attributes.HasFlag(MethodAttributes.Private)) continue;
            var s = md.DecodeSignature(sig, null!);
            string vis = md.Attributes.HasFlag(MethodAttributes.Public) ? "public" :
                         md.Attributes.HasFlag(MethodAttributes.Assembly) ? "internal" : "other";
            string stat = md.Attributes.HasFlag(MethodAttributes.Static) ? " static" : "";
            string ps = string.Join(", ", s.ParameterTypes.ToImmutableArray());
            Console.WriteLine($"    {vis}{stat} {s.ReturnType} {mr.GetString(md.Name)}({ps})");
        }
        Console.WriteLine();
    }

    if (shown == 0) Console.Error.WriteLine("no match");
    return true;
}

static string Full(MetadataReader mr, TypeDefinition td)
{
    string ns = mr.GetString(td.Namespace), n = mr.GetString(td.Name);
    return ns.Length == 0 ? n : ns + "." + n;
}

static string NameOf(MetadataReader mr, EntityHandle h, StringProvider sig) => h.Kind switch
{
    HandleKind.TypeDefinition => Full(mr, mr.GetTypeDefinition((TypeDefinitionHandle)h)),
    HandleKind.TypeReference => Ref(mr, (TypeReferenceHandle)h),
    HandleKind.TypeSpecification => mr.GetTypeSpecification((TypeSpecificationHandle)h).DecodeSignature(sig, null!),
    _ => "?"
};

static string Ref(MetadataReader mr, TypeReferenceHandle h)
{
    var tr = mr.GetTypeReference(h);
    string ns = mr.GetString(tr.Namespace), n = mr.GetString(tr.Name);
    return ns.Length == 0 ? n : ns + "." + n;
}

sealed class StringProvider : ISignatureTypeProvider<string, object?>
{
    public string GetArrayType(string e, ArrayShape s) => e + "[" + new string(',', s.Rank - 1) + "]";
    public string GetByReferenceType(string e) => e + "&";
    public string GetFunctionPointerType(MethodSignature<string> signature) => "fnptr";
    public string GetGenericInstantiation(string generic, ImmutableArray<string> args)
        => generic + "<" + string.Join(", ", args) + ">";
    public string GetGenericMethodParameter(object? gc, int i) => "!!" + i;
    public string GetGenericTypeParameter(object? gc, int i) => "!" + i;
    public string GetModifiedType(string mod, string unmodified, bool isRequired) => unmodified;
    public string GetPinnedType(string e) => e;
    public string GetPointerType(string e) => e + "*";
    public string GetPrimitiveType(PrimitiveTypeCode c) => c.ToString();
    public string GetSZArrayType(string e) => e + "[]";
    public string GetSystemType() => "object";
    public string GetTypeFromDefinition(MetadataReader r, TypeDefinitionHandle h, byte k)
    {
        var td = r.GetTypeDefinition(h);
        string ns = r.GetString(td.Namespace), n = r.GetString(td.Name);
        return ns.Length == 0 ? n : ns + "." + n;
    }
    public string GetTypeFromReference(MetadataReader r, TypeReferenceHandle h, byte k)
    {
        var tr = r.GetTypeReference(h);
        string ns = r.GetString(tr.Namespace), n = r.GetString(tr.Name);
        return ns.Length == 0 ? n : ns + "." + n;
    }
    public string GetTypeFromSpecification(MetadataReader r, object? gc, TypeSpecificationHandle h, byte k)
        => r.GetTypeSpecification(h).DecodeSignature(this, gc);
}
