# Contrats API - HYGITECH-3D

## Vue d'ensemble
Site vitrine pour HYGITECH-3D avec formulaire de contact fonctionnel et optimisation SEO.

## Données actuellement mockées
- `submitContactForm()` dans `/app/frontend/src/data/mock.js`
- Informations entreprise (contact, adresse, services)
- Données de témoignages (actuellement non utilisées dans l'interface)

## API à implémenter

### 1. Endpoint Contact Form
**Route:** `POST /api/contact`

**Body:**
```json
{
  "name": "string (required)",
  "email": "string (required)",
  "phone": "string (required)", 
  "subject": "string (required)",
  "message": "string (required)",
  "hasPets": "boolean",
  "hasVulnerablePeople": "boolean"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Votre demande a été envoyée avec succès. Nous vous recontacterons sous 24h.",
  "id": "string"
}
```

### 2. Modèle MongoDB Contact
```python
class ContactRequest(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    email: str
    phone: str
    subject: str
    message: str
    has_pets: bool = False
    has_vulnerable_people: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
    status: str = "nouveau"  # nouveau, traité, fermé
```

### 3. Fonctionnalités backend requises
- Validation des données du formulaire
- Sauvegarde en base MongoDB
- Envoi d'email de notification (optionnel pour MVP)
- Endpoint pour récupérer les demandes (admin, optionnel)

## Intégration Frontend
1. Remplacer l'import `submitContactForm` de `mock.js`
2. Utiliser `${BACKEND_URL}/api/contact` avec axios
3. Conserver la gestion des états de chargement et toasts
4. Tests de validation des formulaires

## Optimisations SEO déjà implémentées
- Meta tags optimisés pour "désinfection, désinsectisation, dératisation"
- Schema.org JSON-LD pour business local
- Open Graph et Twitter cards
- Structure HTML sémantique
- URLs en français
- Titre et descriptions optimisés

## Fichiers à modifier pour l'intégration
- `/app/frontend/src/components/ContactSection.jsx` : remplacer mock par API
- `/app/backend/server.py` : ajouter route contact
- `/app/backend/requirements.txt` : ajouter deps email si nécessaire

## Tests requis
- Validation formulaire côté backend
- Sauvegarde correcte en MongoDB
- Gestion d'erreurs (email invalide, champs manquants)
- Test d'envoi de formulaire frontend vers backend