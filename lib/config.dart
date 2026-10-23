const String kSupabaseUrl = 'https://nzqqouxjwnalwkinqxxg.supabase.co';

// Chave pública (publishable): quem protege os dados é o RLS, não o sigilo da chave
const String kSupabaseAnonKey =
    'sb_publishable_zVx2GBNavgSYdwWBRNihmg_txxhKOku';

// Domínio fictício (.invalid): a matrícula vira um e-mail interno, sem envio real
const String kDominioLogin = 'chamados-ti.invalid';

// Detecta valores de exemplo que ainda não foram substituídos
bool get configuracaoPendente =>
    kSupabaseUrl.contains('SEU-PROJETO') ||
    kSupabaseAnonKey.startsWith('COLE-AQUI');
