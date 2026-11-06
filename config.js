/* Al Día Sistemas · Douglas's Grooming
   Lo único que hay que cambiar para conectar la app.
   En Supabase: Project Settings → API. */
window.AL_DIA = {
  supabaseUrl: 'https://xjmdtqdzstddeobxnenh.supabase.co',
  supabaseKey: 'sb_publishable_LU2xkId5-RiXHrMrsaILlA_BcQ8sFaf', // llave publishable (nunca la secret / service_role)
  negocio: 'DOUGLAS-01',                          // el mismo código del SQL
  precio: 30000,                                  // mensualidad en colones
  diaPago: 23,                                    // día de pago de cada mes
  sinpe: '8599-4415',                             // SINPE Móvil de Al Día Sistemas
  whatsapp: '50685994415'                         // WhatsApp para el comprobante (con 506)
};
