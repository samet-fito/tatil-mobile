# Kimlik bilgileri ve güvenlik

## Dosya yapısı

| Dosya | Git | Açıklama |
|-------|-----|----------|
| `.env.supabase.local.example` | Evet | Şablon — sadece placeholder değerler |
| `.env.supabase.local` | Hayır | Gerçek token ve OAuth secret'larınız |

Kurulum:

```bash
cp scripts/.env.supabase.local.example scripts/.env.supabase.local
# .env.supabase.local dosyasını doldurun
./scripts/supabase_auth_setup.sh
```

## Asla repoya commit etmeyin

- OAuth client secret (Google, Facebook, Apple)
- Supabase `service_role` anahtarı
- `SUPABASE_ACCESS_TOKEN` (Management API)
- `.p8` Apple private key dosyaları
- Ödeme / 3DS test kartı gerçek bilgileri

## Mobil uygulamadaki Supabase anon key

`lib/constants.dart` içindeki `supabaseAnonKey` istemci tarafında kullanılır; Supabase RLS ile korunması beklenir. Bu anahtar **service_role değildir** — yine de veritabanı politikalarınızı gözden geçirin.

## Sızıntı sonrası yapılacaklar

Eğer OAuth secret veya token bir kez repoya girdiyse (push edilmiş olsun ya da olmasın):

1. **Google Cloud Console** → Credentials → ilgili OAuth client → yeni secret üretin, eskisini iptal edin.
2. **Facebook Developer** → App → Settings → App Secret → Reset.
3. **Supabase** → [Access Tokens](https://supabase.com/dashboard/account/tokens) → eski token'ı revoke edin, yeni oluşturun.
4. `scripts/.env.supabase.local` dosyanızı yeni değerlerle güncelleyin.
5. `./scripts/supabase_auth_setup.sh` ile Supabase auth provider ayarlarını yeniden uygulayın.
