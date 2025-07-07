import * as d3 from 'd3';

class TimelineChart {
  constructor(containerId, data) {
    this.containerId = containerId;
    this.data = data;
    this.margin = { top: 30, right: 30, bottom: 100, left: 40 };
    this.resizeObserver = null;
    
    this.init();
    this.setupResizeObserver();
  }

  getDimensions() {
    const container = d3.select(this.containerId);
    const containerNode = container.node();
    
    if (!containerNode) {
      return {
        width: 1000 - this.margin.left - this.margin.right,
        height: 250 - this.margin.top - this.margin.bottom
      };
    }
    
    const containerRect = containerNode.getBoundingClientRect();
    const containerWidth = containerRect.width;
    
    return {
      width: Math.max(containerWidth - this.margin.left - this.margin.right, 400),
      height: 250 - this.margin.top - this.margin.bottom
    };
  }

  setupResizeObserver() {
    const container = d3.select(this.containerId).node();
    if (!container) return;

    this.resizeObserver = new ResizeObserver(() => {
      this.resize();
    });
    
    this.resizeObserver.observe(container);
  }

  resize() {
    const dimensions = this.getDimensions();
    this.width = dimensions.width;
    this.height = dimensions.height;
    
    // Re-render the chart with new dimensions
    this.init();
  }

  init() {
    const container = d3.select(this.containerId);
    if (container.empty()) {
      console.error('Container not found:', this.containerId);
      return;
    }

    // Get current dimensions
    const dimensions = this.getDimensions();
    this.width = dimensions.width;
    this.height = dimensions.height;

    // Clear existing content
    container.html('');

    // Create SVG
    const svg = container.append('svg')
      .attr('width', this.width + this.margin.left + this.margin.right)
      .attr('height', this.height + this.margin.top + this.margin.bottom)
      .style('max-width', '100%')
      .style('height', 'auto');

    const g = svg.append('g')
      .attr('transform', `translate(${this.margin.left},${this.margin.top})`);

    // Parse dates
    const events = this.data.map(d => ({
      ...d,
      date: new Date(d.checked_at)
    }));

    if (events.length === 0) {
      g.append('text')
        .attr('x', this.width / 2)
        .attr('y', this.height / 2)
        .attr('text-anchor', 'middle')
        .attr('fill', '#6b7280')
        .style('font-size', '14px')
        .style('font-weight', '500')
        .text('No events to display');
      return;
    }

    // Create scales
    const timeExtent = d3.extent(events, d => d.date);
    const xScale = d3.scaleTime()
      .domain(timeExtent)
      .range([0, this.width]);

    const yScale = d3.scaleLinear()
      .domain([0, 1])
      .range([this.height, 0]);

    // Create color scale for status
    const colorScale = d3.scaleOrdinal()
      .domain(['up', 'down', 'degraded', 'unknown', 'paused'])
      .range(['#10b981', '#ef4444', '#f59e0b', '#6b7280', '#3b82f6']);

    // Add X axis
    const xAxis = d3.axisBottom(xScale)
      .tickFormat(d3.timeFormat('%H:%M'))
      .ticks(Math.min(8, Math.floor(this.width / 100))); // Adjust ticks based on width

    g.append('g')
      .attr('transform', `translate(0,${this.height})`)
      .call(xAxis)
      .selectAll('text')
      .style('text-anchor', 'end')
      .style('font-size', '11px')
      .style('font-weight', '500')
      .attr('dx', '-.8em')
      .attr('dy', '.15em')
      .attr('transform', 'rotate(-45)');

    // Add Y axis (simple line at bottom)
    g.append('line')
      .attr('x1', 0)
      .attr('y1', this.height)
      .attr('x2', this.width)
      .attr('y2', this.height)
      .attr('stroke', '#d1d5db')
      .attr('stroke-width', 2);

    // Add events as circles
    const eventGroups = g.selectAll('.event')
      .data(events)
      .enter()
      .append('g')
      .attr('class', 'event')
      .attr('transform', d => `translate(${xScale(d.date)},${this.height - 20})`);

    // Add circles for events
    eventGroups.append('circle')
      .attr('r', 8)
      .attr('fill', d => colorScale(d.status))
      .attr('stroke', 'white')
      .attr('stroke-width', 2)
      .style('cursor', 'pointer')
      .style('filter', 'drop-shadow(0 2px 4px rgba(0,0,0,0.1))')
      .on('mouseover', function(event, d) {
        d3.select(this)
          .attr('r', 12)
          .style('filter', 'drop-shadow(0 4px 8px rgba(0,0,0,0.2))');
        
        // Show tooltip
        const tooltip = d3.select('body').append('div')
          .attr('class', 'timeline-tooltip')
          .style('position', 'absolute')
          .style('background', 'rgba(0,0,0,0.9)')
          .style('color', 'white')
          .style('padding', '12px')
          .style('border-radius', '8px')
          .style('font-size', '13px')
          .style('font-weight', '500')
          .style('pointer-events', 'none')
          .style('z-index', '1000')
          .style('box-shadow', '0 4px 12px rgba(0,0,0,0.3)')
          .style('border', '1px solid rgba(255,255,255,0.1)');

        tooltip.html(`
          <div style="margin-bottom: 4px;">
            <span style="color: ${colorScale(d.status)}; font-weight: 600;">●</span>
            <strong style="margin-left: 6px;">${d.status.toUpperCase()}</strong>
          </div>
          <div style="color: #e5e7eb; font-size: 12px; margin-bottom: 4px;">
            ${d3.timeFormat('%Y-%m-%d %H:%M:%S')(d.date)}
          </div>
          ${d.message ? `<div style="color: #d1d5db; font-size: 12px; font-style: italic;">${d.message}</div>` : ''}
        `);

        tooltip.style('left', (event.pageX + 10) + 'px')
               .style('top', (event.pageY - 10) + 'px');
      })
      .on('mouseout', function() {
        d3.select(this)
          .attr('r', 8)
          .style('filter', 'drop-shadow(0 2px 4px rgba(0,0,0,0.1))');
        d3.selectAll('.timeline-tooltip').remove();
      });

    // Add status labels above events with improved styling
    eventGroups.append('text')
      .attr('y', -15)
      .attr('text-anchor', 'middle')
      .style('font-size', '11px')
      .style('font-weight', '600')
      .style('text-transform', 'uppercase')
      .style('letter-spacing', '0.5px')
      .attr('fill', d => colorScale(d.status))
      .text(d => d.status);

    // Add time labels above events with improved styling
    eventGroups.append('text')
      .attr('y', -30)
      .attr('text-anchor', 'middle')
      .style('font-size', '11px')
      .style('font-weight', '600')
      .style('text-transform', 'uppercase')
      .style('letter-spacing', '0.5px')
      .attr('fill', d => colorScale(d.status))
      .text(d => d3.timeFormat('%H:%M')(d.date));

    // Add connecting lines between events
    if (events.length > 1) {
      const lineData = [];
      for (let i = 0; i < events.length - 1; i++) {
        lineData.push({
          x1: xScale(events[i].date),
          y1: this.height - 20,
          x2: xScale(events[i + 1].date),
          y2: this.height - 20,
          status: events[i].status
        });
      }

      g.selectAll('.connection-line')
        .data(lineData)
        .enter()
        .append('line')
        .attr('class', 'connection-line')
        .attr('x1', d => d.x1)
        .attr('y1', d => d.y1)
        .attr('x2', d => d.x2)
        .attr('y2', d => d.y2)
        .attr('stroke', d => colorScale(d.status))
        .attr('stroke-width', 3)
        .attr('opacity', 0.6)
        .style('filter', 'drop-shadow(0 1px 2px rgba(0,0,0,0.1))');
    }
  }

  update(newData) {
    this.data = newData;
    this.init();
  }

  destroy() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }
    d3.select(this.containerId).html('');
  }
}

// Make it available globally
window.TimelineChart = TimelineChart; 