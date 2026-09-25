const { GoogleGenerativeAI } = require('@google/generative-ai');

class GeminiService {
  constructor() {
    this.apiKey = process.env.GEMINI_API_KEY;
    this.genAI = null;
    
    this.initClient();
  }

  initClient() {
    this.apiKey = process.env.GEMINI_API_KEY;
    if (this.apiKey) {
      try {
        this.genAI = new GoogleGenerativeAI(this.apiKey);
      } catch (err) {
        console.error('Failed to initialize Gemini AI client:', err.message);
        this.genAI = null;
      }
    } else {
      this.genAI = null;
    }
  }

  generateFallbackExplanation(crop, pestNames, diseaseNames) {
    const issues = [pestNames, diseaseNames].filter(Boolean).join(' and ');
    const target = issues ? `${issues} on ${crop}` : crop;

    return `### 1. 🧪 Chemical Treatments & Recommended Field Dosages
- Apply approved chemical formulations targeted for ${target}.
- Follow safety protocols, wear protective clothing, and apply during early morning or cool evening hours.

### 2. 🌿 Organic & Eco-Friendly Alternatives
- Apply cold-pressed Neem oil extract (5ml per liter of water with organic emulsifier) every 7-10 days.
- Utilize bio-pesticides or beneficial natural predators to suppress pest/disease pressure.

### 3. 💧 Cultural Water & Soil Management
- Practice strict field sanitation by removing and burning/burying severely affected plant parts.
- Avoid over-irrigation, promote proper drainage, and maintain optimal soil aeration.

### 4. 🛡️ Preventive Steps to Protect Remaining Yield
- Inspect fields weekly for early symptoms of spread or re-infestation.
- Practice crop rotation with non-host plants and consult your local agricultural extension officer.

*(Note: Add your GEMINI_API_KEY to backend/.env to unlock live real-time Gemini AI customized field guidance).*`;
  }

  async generateExplanation(crop = 'crop', detections = { pests: [], diseases: [] }) {
    // Refresh API key check in case env was updated
    this.initClient();

    const pestNames = detections.pests ? detections.pests.map(p => p.name).join(', ') : '';
    const diseaseNames = detections.diseases ? detections.diseases.map(d => d.name).join(', ') : '';

    if (!pestNames && !diseaseNames) {
      return {
        available: true,
        explanation: "No confident pests or diseases were detected in the image.\n\nGeneral Advice:\nEnsure clear lighting and focused images showing affected plant parts (leaves, stems, or fruits). Consult a local agricultural extension officer if crop symptoms persist."
      };
    }

    if (!this.apiKey || !this.genAI) {
      return {
        available: true,
        fallback: true,
        message: 'Gemini API key not set in backend/.env. Returning standard expert agricultural guidance.',
        explanation: this.generateFallbackExplanation(crop, pestNames, diseaseNames)
      };
    }

    const prompt = `
You are an expert agricultural advisor assisting a farmer with AgriScan AI.
Computer Vision models detected the following conditions on a ${crop}:
${pestNames ? `- Pests: ${pestNames}` : ''}
${diseaseNames ? `- Diseases: ${diseaseNames}` : ''}

Generate a comprehensive, structured agricultural guidance document with the following four sections:

1. 🧪 Chemical Treatments & Recommended Field Dosages
- Approved active ingredients and standard agricultural application guidance.
- Safety measures and recommended application timings.

2. 🌿 Organic & Eco-Friendly Alternatives
- Botanical extracts (e.g. Neem oil, bio-pesticides).
- Natural predators, beneficial microbes, and eco-friendly management.

3. 💧 Cultural Water & Soil Management
- Irrigation controls (e.g. alternate wetting and drying, soil moisture).
- Soil nutrient balance, weed clearance, and field sanitation.

4. 🛡️ Preventive Steps to Protect Remaining Yield
- Monitoring schedules, crop rotation, and barrier strategies.
- When to consult local agricultural officers for field confirmation.

Keep the advice practical, highly structured, and actionable for farmers.
`;

    const candidateModels = ['gemini-2.0-flash', 'gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-pro'];
    let text = null;
    let lastError = null;

    for (const modelName of candidateModels) {
      try {
        const model = this.genAI.getGenerativeModel({ model: modelName });
        const result = await model.generateContent(prompt);
        const response = await result.response;
        text = response.text();
        if (text) break;
      } catch (err) {
        lastError = err;
      }
    }

    if (text) {
      return {
        available: true,
        explanation: text
      };
    }

    console.error('Gemini explanation generation error:', lastError ? lastError.message : 'No candidate model responded');
    return {
      available: true,
      fallback: true,
      message: 'Gemini live service query failed or API key invalid. Returning standard expert agricultural guidance.',
      explanation: this.generateFallbackExplanation(crop, pestNames, diseaseNames),
      error: lastError ? lastError.message : 'Unknown error'
    };
  }
}

module.exports = new GeminiService();
