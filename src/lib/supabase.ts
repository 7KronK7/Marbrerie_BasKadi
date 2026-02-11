import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || ''
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''

if (!supabaseUrl || !supabaseKey) {
  console.error('Variables Supabase manquantes !')
}

export const supabase = createClient(supabaseUrl, supabaseKey)

export type LotMarbre = {
  id: string
  reference_interne: string
  origine_carriere: string
  date_importation: string
  type_marbre: string
  statut: 'en_transit' | 'en_stock' | 'reserve' | 'vendu' | 'pose'
  prix_coutant_total: number
  photos_lot?: string[]
}

export async function getLotsEnStock() {
  const { data, error } = await supabase
    .from('lots_marbre')
    .select('*')
    .eq('statut', 'en_stock')
    .order('date_creation', { ascending: false })
  
  if (error) {
    console.error('Erreur:', error)
    throw error
  }
  return data as LotMarbre[]
}