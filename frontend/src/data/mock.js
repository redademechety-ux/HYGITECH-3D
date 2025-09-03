// Données mockées pour le site Hygitech-3d

export const companyInfo = {
  name: "HYGITECH-3D",
  slogan: "Solutions d'hygiène professionnelles",
  address: {
    street: "122 BOULEVARD GABRIEL PERI",
    postalCode: "92240",
    city: "MALAKOFF",
    region: "Île-de-France"
  },
  contact: {
    phone: "01 XX XX XX XX", // À remplacer par le vrai numéro
    whatsapp: "33XXXXXXXXX", // À remplacer par le vrai numéro WhatsApp
    email: "contact@hygitech-3d.fr" // À confirmer
  },
  pricing: {
    startingPrice: 99,
    currency: "EUR",
    taxIncluded: true,
    travelFees: "Variables selon la zone d'intervention"
  }
};

export const services = [
  {
    id: "desinfection",
    name: "Désinfection",
    description: "Élimination des virus, bactéries et germes pathogènes",
    keywords: ["désinfection", "virus", "bactéries", "covid", "hygiène"],
    details: [
      "Surfaces et équipements",
      "Espaces de travail", 
      "Véhicules",
      "Locaux commerciaux"
    ]
  },
  {
    id: "desinsectisation", 
    name: "Désinsectisation",
    description: "Traitement contre tous types d'insectes nuisibles",
    keywords: ["désinsectisation", "insectes", "cafards", "fourmis", "punaises"],
    details: [
      "Fourmis, cafards",
      "Puces, punaises de lit",
      "Guêpes, frelons", 
      "Mites alimentaires"
    ]
  },
  {
    id: "deratisation",
    name: "Dératisation", 
    description: "Élimination et prévention des rongeurs",
    keywords: ["dératisation", "rats", "souris", "rongeurs"],
    details: [
      "Rats et souris",
      "Mulots",
      "Pose de pièges sécurisés",
      "Bouchage des points d'accès"
    ]
  },
  {
    id: "nettoyage-chantier",
    name: "Nettoyage Fin de Chantier",
    description: "Nettoyage spécialisé après travaux de construction",
    keywords: ["nettoyage", "chantier", "construction", "après travaux"],
    details: [
      "Évacuation des gravats",
      "Nettoyage des poussières",
      "Remise en état",
      "Livraison clé en main"
    ]
  }
];

export const interventionZones = [
  "Paris (75)",
  "Hauts-de-Seine (92)", 
  "Seine-Saint-Denis (93)",
  "Val-de-Marne (94)",
  "Seine-et-Marne (77)",
  "Yvelines (78)",
  "Essonne (91)",
  "Val-d'Oise (95)"
];

export const clientTypes = [
  {
    type: "Entreprises",
    examples: ["Usines", "Entrepôts", "Bureaux", "Locaux industriels"],
    icon: "building"
  },
  {
    type: "Commerces", 
    examples: ["Boulangeries", "Cafés", "Restaurants", "Magasins"],
    icon: "store"
  },
  {
    type: "Particuliers",
    examples: ["Maisons individuelles", "Appartements", "Résidences"],
    icon: "home"
  },
  {
    type: "Collectivités",
    examples: ["Mairies", "Parcs publics", "Jardins", "Établissements publics"],
    icon: "trees"
  }
];

export const testimonials = [
  {
    id: 1,
    name: "Marie Dubois",
    type: "Particulier",
    location: "Malakoff (92)",
    rating: 5,
    comment: "Intervention rapide et efficace pour un problème de cafards. L'équipe est professionnelle et rassurante.",
    service: "Désinsectisation"
  },
  {
    id: 2, 
    name: "Restaurant Le Bistrot",
    type: "Commerce",
    location: "Paris 15ème",
    rating: 5,
    comment: "Excellent service de dératisation. Problème résolu durablement et conseils précieux pour la prévention.",
    service: "Dératisation"
  },
  {
    id: 3,
    name: "Entreprise LogiTech",
    type: "Entreprise", 
    location: "Boulogne-Billancourt (92)",
    rating: 5,
    comment: "Désinfection complète de nos bureaux pendant le confinement. Service irréprochable et tarifs transparents.",
    service: "Désinfection"
  }
];

export const faqData = [
  {
    question: "Quel est le délai d'intervention ?",
    answer: "Nous intervenons généralement sous 24-48h selon l'urgence de la situation et votre zone géographique en Île-de-France."
  },
  {
    question: "Les traitements sont-ils dangereux pour les animaux domestiques ?",
    answer: "Nous utilisons des produits certifiés et adaptons nos méthodes selon la présence d'animaux. Il est important de nous signaler leur présence lors de la prise de rendez-vous."
  },
  {
    question: "Le devis est-il vraiment gratuit ?",
    answer: "Oui, nous établissons un devis gratuit et sans engagement après évaluation de votre situation, soit par téléphone soit lors d'une visite sur site."
  },
  {
    question: "Que comprend le tarif à partir de 99€ ?",
    answer: "Ce tarif comprend l'intervention de base. Les frais de déplacement sont variables selon votre localisation en Île-de-France et seront précisés dans le devis."
  },
  {
    question: "Proposez-vous un suivi après intervention ?",
    answer: "Oui, nous assurons un suivi post-intervention et proposons des contrats de maintenance préventive selon vos besoins."
  }
];

// Fonction pour simuler l'envoi du formulaire
export const submitContactForm = async (formData) => {
  // Simulation d'un délai réseau
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  console.log("Formulaire soumis (MOCK):", formData);
  
  // Simuler une réponse réussie
  return {
    success: true,
    message: "Votre demande a été envoyée avec succès. Nous vous recontacterons sous 24h.",
    id: Math.random().toString(36).substr(2, 9)
  };
};