import React, { useState } from 'react';
import { aiService, InvestigationReport } from '../services/ai.service';
import '../styles/AIComponents.css';

interface InvestigationReportProps {
  touristId: string;
  tripId: string;
  incidentType?: string;
}

export const InvestigationReportViewer: React.FC<InvestigationReportProps> = ({
  touristId,
  tripId,
  incidentType = 'anomaly',
}) => {
  const [report, setReport] = useState<InvestigationReport | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [expanded, setExpanded] = useState<Record<string, boolean>>({});

  const generateReport = async () => {
    setLoading(true);
    setError(null);

    try {
      const result = await aiService.generateInvestigationReport(
        touristId,
        tripId,
        incidentType,
        24
      );
      setReport(result);
      // Auto-expand first section
      if (result.sections && Object.keys(result.sections).length > 0) {
        setExpanded({ [Object.keys(result.sections)[0]]: true });
      }
    } catch (err: any) {
      setError(err.message || 'Failed to generate report');
    } finally {
      setLoading(false);
    }
  };

  const toggleSection = (sectionName: string) => {
    setExpanded(prev => ({
      ...prev,
      [sectionName]: !prev[sectionName]
    }));
  };


  const downloadReport = async () => {
    if (!report) return;

    // Dynamic import to avoid bundle size issues
    const jsPDFModule = await import('jspdf');
    const jsPDF = jsPDFModule.default;
    const doc = new jsPDF();
    
    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();
    const margin = 20;
    const maxWidth = pageWidth - 2 * margin;
    let yPos = 20;

    // Header
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.text('INVESTIGATION REPORT', pageWidth / 2, yPos, { align: 'center' });
    yPos += 10;

    // Metadata
    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.text(`Case: ${touristId} / ${tripId}`, margin, yPos);
    yPos += 6;
    doc.text(`Type: ${incidentType}`, margin, yPos);
    yPos += 6;
    doc.text(`Generated: ${new Date(report.generated_at).toLocaleString()}`, margin, yPos);
    yPos += 10;

    // Try to add location map if we have coordinates
    try {
      // Get incident location from API or props
      const response = await fetch(`http://10.191.242.40:5001/api/incidents?limit=100`);
      const data = await response.json();
      
      // Find the incident by tripId
      const incident = data.data?.find((inc: any) => inc.id === tripId);
      
      if (incident && incident.location) {
        const { latitude, longitude } = incident.location;
        
        // Create static map URL using OpenStreetMap tiles
        const zoom = 15;
        const width = 400;
        const height = 300;
        
        // Use StaticMap API or create a simple marker map
        const mapUrl = `https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/pin-l-marker+ff0000(${longitude},${latitude})/${longitude},${latitude},${zoom},0/${width}x${height}?access_token=pk.eyJ1IjoidG91cmd1YXJkIiwiYSI6ImNtNGRlZmFiYTA0MTEya3M5emV4NjRuYnEifQ.invalid`;
        
        // Use a free alternative - OpenStreetMap static render
        const osmMapUrl = `https://staticmap.openstreetmap.de/staticmap.php?center=${latitude},${longitude}&zoom=${zoom}&size=${width}x${height}&markers=${latitude},${longitude},red-pushpin`;
        
        // Divider
        doc.setDrawColor(200, 200, 200);
        doc.line(margin, yPos, pageWidth - margin, yPos);
        yPos += 8;
        
        // Location section
        doc.setFontSize(12);
        doc.setFont('helvetica', 'bold');
        doc.text('INCIDENT LOCATION', margin, yPos);
        yPos += 8;
        
        doc.setFontSize(10);
        doc.setFont('helvetica', 'normal');
        doc.text(`Coordinates: ${latitude.toFixed(6)}, ${longitude.toFixed(6)}`, margin, yPos);
        yPos += 6;
        doc.text(`Map: Incident location marked in red`, margin, yPos);
        yPos += 10;
        
        // Try to load and add map image
        try {
          const img = new Image();
          img.crossOrigin = 'anonymous';
          
          await new Promise((resolve, reject) => {
            img.onload = () => {
              // Add map to PDF
              const imgWidth = 160;
              const imgHeight = 120;
              doc.addImage(img, 'PNG', margin, yPos, imgWidth, imgHeight);
              yPos += imgHeight + 10;
              resolve(true);
            };
            img.onerror = () => {
              // Fallback: just show coordinates
              doc.text(`[Map unavailable - Location: ${latitude}, ${longitude}]`, margin, yPos);
              yPos += 10;
              resolve(false);
            };
            img.src = osmMapUrl;
            
            // Timeout after 3 seconds
            setTimeout(() => reject(new Error('Map load timeout')), 3000);
          }).catch(() => {
            // Fallback on timeout
            doc.text(`[Map unavailable - Location: ${latitude}, ${longitude}]`, margin, yPos);
            yPos += 10;
          });
        } catch (mapError) {
          console.warn('Could not load map:', mapError);
          doc.text(`[Map service unavailable]`, margin, yPos);
          yPos += 10;
        }
      }
    } catch (error) {
      console.warn('Could not fetch incident location:', error);
      // Continue without map
    }

    // Divider
    doc.setDrawColor(200, 200, 200);
    doc.line(margin, yPos, pageWidth - margin, yPos);
    yPos += 10;

    // Report content
    doc.setFontSize(11);
    const lines = report.full_report.split('\n');
    
    for (const line of lines) {
      // Check if we need a new page
      if (yPos > pageHeight - 30) {
        doc.addPage();
        yPos = 20;
      }

      if (line.trim() === '') {
        yPos += 4;
        continue;
      }

      // Section headers (all caps)
      if (line.toUpperCase() === line && line.length > 5 && line.length < 50) {
        doc.setFont('helvetica', 'bold');
        doc.setFontSize(12);
        const splitHeader = doc.splitTextToSize(line, maxWidth);
        doc.text(splitHeader, margin, yPos);
        yPos += splitHeader.length * 6 + 4;
        doc.setFont('helvetica', 'normal');
        doc.setFontSize(11);
      } else {
        // Regular text
        const splitText = doc.splitTextToSize(line, maxWidth);
        doc.text(splitText, margin, yPos);
        yPos += splitText.length * 5;
      }
    }

    // Footer
    const totalPages = doc.internal.pages.length - 1;
    for (let i = 1; i <= totalPages; i++) {
      doc.setPage(i);
      doc.setFontSize(8);
      doc.setTextColor(128);
      doc.text(
        `Page ${i} of ${totalPages} | TourGuard Investigation Report | Confidential`,
        pageWidth / 2,
        pageHeight - 10,
        { align: 'center' }
      );
    }

    // Download
    doc.save(`Investigation_Report_${touristId}_${new Date().toISOString().split('T')[0]}.pdf`);
  };


  if (loading) {
    return (
      <div className="investigation-report loading">
        <div className="spinner"></div>
        <p>Generating AI-powered investigation report...</p>
        <small>This may take 3-5 seconds</small>
      </div>
    );
  }

  if (error) {
    return (
      <div className="investigation-report error">
        <p className="error-message">⚠️ {error}</p>
        <button onClick={generateReport}>Retry</button>
      </div>
    );
  }

  if (!report) {
    return (
      <div className="investigation-report empty">
        <div className="empty-state">
          <h3>📄 Investigation Report</h3>
          <p>Generate a comprehensive AI-powered investigation report</p>
          <button onClick={generateReport} className="generate-btn">
            🤖 Generate Report
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="investigation-report">
      <div className="report-header">
        <div>
          <h2>🔍 Investigation Report</h2>
          <p className="report-meta">
            Case: {report.tourist_id} / {report.trip_id} | 
            Type: {report.incident_type} | 
            Generated: {new Date(report.generated_at).toLocaleString()}
          </p>
        </div>
        <div className="report-actions">
          <button onClick={downloadReport} className="download-btn">
            ⬇️ Download
          </button>
          <button onClick={generateReport} className="refresh-btn">
            🔄 Regenerate
          </button>
        </div>
      </div>

      <div className="report-sections">
        {Object.entries(report.sections).map(([sectionName, content]) => (
          <div key={sectionName} className="report-section">
            <div 
              className="section-header"
              onClick={() => toggleSection(sectionName)}
            >
              <h3>
                {expanded[sectionName] ? '▼' : '▶'} {sectionName}
              </h3>
            </div>
            {expanded[sectionName] && (
              <div className="section-content">
                <pre>{content}</pre>
              </div>
            )}
          </div>
        ))}
      </div>

      <div className="full-report-section">
        <details>
          <summary>View Full Report (Markdown)</summary>
          <pre className="full-report-text">{report.full_report}</pre>
        </details>
      </div>
    </div>
  );
};

export default InvestigationReportViewer;
